package main

import (
	"database/sql"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	_ "github.com/lib/pq"
)


type Apartment struct {
	ID           int     `json:"id"`
	Title        string  `json:"title"`
	Address      string  `json:"address"`
	ImageLink    string  `json:"image_link"`
	Description  string  `json:"description"`
	SquareMeters int     `json:"square_meters"`
	Bedrooms     int     `json:"bedrooms"`
	Price        float64 `json:"price"`
	Favourite    bool    `json:"favourite"`
}

type CartItem struct {
    ID          int `json:"id"`
    ApartmentID int `json:"apartment_id"`
    UserID      int `json:"user_id"`
    Quantity    int `json:"quantity"`
}

var db *sql.DB

func initDB() {
	var err error
	connStr := "host=localhost port=5432 user=postgres password=1111 dbname=apartments_db sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatalf("Ошибка подключения к базе данных: %v", err)
	}

	err = db.Ping()
	if err != nil {
		log.Fatalf("Не удалось подключиться к базе данных: %v", err)
	}

	log.Println("Подключение к базе данных успешно выполнено!")
}

func getApartmentsHandler(c *gin.Context) {
	rows, err := db.Query("SELECT id, title, address, image_link, description, square_meters, bedrooms, price, favourite FROM apartments")
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения данных"})
		return
	}
	defer rows.Close()

	var apartments []Apartment
	for rows.Next() {
		var a Apartment
		if err := rows.Scan(&a.ID, &a.Title, &a.Address, &a.ImageLink, &a.Description, &a.SquareMeters, &a.Bedrooms, &a.Price, &a.Favourite); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обработки данных"})
			return
		}
		apartments = append(apartments, a)
	}

	c.JSON(http.StatusOK, apartments)
}

func createApartmentHandler(c *gin.Context) {
	var newApartment Apartment
	if err := c.ShouldBindJSON(&newApartment); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	query := `
		INSERT INTO apartments (title, address, image_link, description, square_meters, bedrooms, price, favourite)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		RETURNING id
	`
	err := db.QueryRow(query, newApartment.Title, newApartment.Address, newApartment.ImageLink, newApartment.Description,
		newApartment.SquareMeters, newApartment.Bedrooms, newApartment.Price, newApartment.Favourite).Scan(&newApartment.ID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при добавлении квартиры"})
		return
	}

	c.JSON(http.StatusOK, newApartment)
}

func getApartmentByIDHandler(c *gin.Context) {
	id := c.Param("id")

	var apartment Apartment
	query := "SELECT id, title, address, image_link, description, square_meters, bedrooms, price, favourite FROM apartments WHERE id = $1"
	err := db.QueryRow(query, id).Scan(&apartment.ID, &apartment.Title, &apartment.Address, &apartment.ImageLink, &apartment.Description, &apartment.SquareMeters, &apartment.Bedrooms, &apartment.Price, &apartment.Favourite)
	if err == sql.ErrNoRows {
		c.JSON(http.StatusNotFound, gin.H{"error": "Квартира не найдена"})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при получении данных"})
		return
	}

	c.JSON(http.StatusOK, apartment)
}

func updateApartmentHandler(c *gin.Context) {
	id := c.Param("id")

	var updatedFields Apartment
	if err := c.ShouldBindJSON(&updatedFields); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
		return
	}

	query := `
		UPDATE apartments
		SET title = COALESCE(NULLIF($1, ''), title),
		    address = COALESCE(NULLIF($2, ''), address),
		    image_link = COALESCE(NULLIF($3, ''), image_link),
		    description = COALESCE(NULLIF($4, ''), description),
		    square_meters = COALESCE(NULLIF($5::int, 0), square_meters),
		    bedrooms = COALESCE(NULLIF($6::int, 0), bedrooms),
		    price = COALESCE(NULLIF($7::numeric, 0), price),
		    favourite = COALESCE($8, favourite)
		WHERE id = $9
	`
	_, err := db.Exec(query, updatedFields.Title, updatedFields.Address, updatedFields.ImageLink, updatedFields.Description,
		updatedFields.SquareMeters, updatedFields.Bedrooms, updatedFields.Price, updatedFields.Favourite, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при обновлении данных"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Квартира обновлена"})
}
func getCartHandler(c *gin.Context) {
    userID := c.Param("user_id")
    rows, err := db.Query("SELECT id, apartment_id, user_id, quantity FROM cart WHERE user_id = $1", userID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка получения данных корзины"})
        return
    }
    defer rows.Close()

    var cartItems []CartItem
    for rows.Next() {
        var item CartItem
        if err := rows.Scan(&item.ID, &item.ApartmentID, &item.UserID, &item.Quantity); err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обработки данных корзины"})
            return
        }
        cartItems = append(cartItems, item)
    }

    c.JSON(http.StatusOK, cartItems)
}

func addToCartHandler(c *gin.Context) {
    var item CartItem
    if err := c.ShouldBindJSON(&item); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Некорректный формат JSON"})
        return
    }

    query := `
        INSERT INTO cart (apartment_id, user_id, quantity)
        VALUES ($1, $2, $3)
        ON CONFLICT (apartment_id, user_id) DO UPDATE SET quantity = cart.quantity + 1
        RETURNING id
    `
    err := db.QueryRow(query, item.ApartmentID, item.UserID, item.Quantity).Scan(&item.ID)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка добавления в корзину"})
        return
    }

    c.JSON(http.StatusOK, item)
}


func removeFromCartHandler(c *gin.Context) {
	userID := c.Param("user_id")
	apartmentID := c.Param("apartment_id")

	query := "DELETE FROM cart WHERE user_id = $1 AND apartment_id = $2"
	_, err := db.Exec(query, userID, apartmentID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка удаления из корзины"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Элемент удален из корзины"})
}


func deleteApartmentHandler(c *gin.Context) {
	id := c.Param("id")

	query := "DELETE FROM apartments WHERE id = $1"
	_, err := db.Exec(query, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка при удалении квартиры"})
		return
	}

	c.JSON(http.StatusNoContent, gin.H{"message": "Квартира удалена"})
}

func toggleFavouriteHandler(c *gin.Context) {
	id := c.Param("id")

	query := `
		UPDATE apartments
		SET favourite = NOT favourite
		WHERE id = $1
	`
	_, err := db.Exec(query, id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Ошибка обновления статуса избранного"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Статус избранного обновлен"})
}

func main() {

	initDB()

	r := gin.Default()

	r.GET("/apartments", getApartmentsHandler)
	r.POST("/apartments/create", createApartmentHandler)
	r.GET("/apartments/:id", getApartmentByIDHandler)
	r.PUT("/apartments/update/:id", updateApartmentHandler)
	r.DELETE("/apartments/delete/:id", deleteApartmentHandler)
	r.PUT("/apartments/favourite/:id", toggleFavouriteHandler)
    r.GET("/cart/:user_id", getCartHandler)
    r.POST("/cart", addToCartHandler)
    r.DELETE("/cart/:user_id/:apartment_id", removeFromCartHandler)


	log.Println("Сервер запущен на порту 8080")
	r.Run(":8080")
}
