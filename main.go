package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func setupRouter() *gin.Engine {
	router := gin.Default()
	router.LoadHTMLGlob("static/*")
	router.Static("/static", "./static")

	router.GET("/", index)
	router.GET("/ping", ping)

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

func main() {
	r := setupRouter()
	r.Run(":8080")
}
