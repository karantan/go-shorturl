package main

import (
	"embed"
	"net/http"
	"path/filepath"
	"shorturl/db"
	"shorturl/logger"
	"shorturl/utils"
	"time"

	"github.com/gin-gonic/gin"
)

var log = logger.New("main", false)

//go:embed static/index.html
//go:embed static/index.js
//go:embed static/style.css
var staticFS embed.FS

const (
	dbBucket = "URLs"
	database = "shorturl.db"
)

func setupRouter() *gin.Engine {
	router := gin.Default()

	// Add static assets to binary.
	// See https://github.com/gin-gonic/examples/tree/master/assets-in-binary
	// templ := template.Must(template.New("").ParseFS(staticFS, "static/index.html"))
	// router.SetHTMLTemplate(templ)
	// router.StaticFS("/public", http.FS(staticFS))

	// Uncoment this for faster html and css development
	router.LoadHTMLGlob("static/index.html")
	router.Static("/public/static", "./static")

	router.GET("/", index)
	router.GET("/ping", ping)
	router.GET("/list", list)
	router.POST("/create", create)

	return router
}

func index(c *gin.Context) {
	c.HTML(http.StatusOK, "index.html", gin.H{
		"title": "Dunder Mifflin",
	})
}

func ping(c *gin.Context) {
	c.String(200, "pong")
}

type ShortURL struct {
	Prefix string
	URL    string
}

func create(c *gin.Context) {
	var shortURL ShortURL
	if err := c.BindJSON(&shortURL); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	db, err := db.GetDB(filepath.Join(utils.RootDir(), database), false)
	defer db.Close()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	db.Put(dbBucket, shortURL.Prefix, shortURL.URL)

	var msg struct {
		Message string `json:"message"`
		Status  int    `json:"status"`
	}
	msg.Message = "Saved"
	msg.Status = 200

	// mimic some hard processing
	time.Sleep(1 * time.Second)
	c.JSON(http.StatusOK, msg)
}

func list(c *gin.Context) {
	db, err := db.GetDB(filepath.Join(utils.RootDir(), database), true)
	defer db.Close()
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	data, err := db.List(dbBucket)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"title": "Dunder Mifflin",
		"data":  data,
	})
}

func main() {
	r := setupRouter()
	r.Run()
}
