package main

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/assert"
)

// Functional test
func TestPingRoute(t *testing.T) {
	assert := assert.New(t)
	router := setupRouter()

	w := httptest.NewRecorder()
	req, _ := http.NewRequest("GET", "/ping", nil)
	router.ServeHTTP(w, req)

	assert.Equal(200, w.Code)
	assert.Equal("pong", w.Body.String())
}

// Unit test
func TestPing(t *testing.T) {
	assert := assert.New(t)
	w := httptest.NewRecorder()
	c, _ := gin.CreateTestContext(w)
	ping(c)

	assert.Equal(w.Code, 200)
	assert.Equal(w.Body.String(), "pong")
}
