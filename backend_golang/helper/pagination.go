package helper

import (
	"math"
	"strconv"

	"github.com/gin-gonic/gin"
)

const DefaultPerPage = 20
const MaxPerPage = 100

// PageParams extracts pagination parameters from the request query string.
func PageParams(c *gin.Context) (page, perPage int) {
	page, _ = strconv.Atoi(c.DefaultQuery("page", "1"))
	perPage, _ = strconv.Atoi(c.DefaultQuery("per_page", strconv.Itoa(DefaultPerPage)))

	if page < 1 {
		page = 1
	}
	if perPage < 1 {
		perPage = DefaultPerPage
	}
	if perPage > MaxPerPage {
		perPage = MaxPerPage
	}
	return
}

// Offset calculates the SQL OFFSET value from page and perPage.
func Offset(page, perPage int) int {
	return (page - 1) * perPage
}

// LastPage calculates the last page number.
func LastPage(total int64, perPage int) int {
	if perPage <= 0 {
		return 1
	}
	return int(math.Ceil(float64(total) / float64(perPage)))
}
