package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// employee represents data about an employee.
type employee struct {
	ID       string `json:"id"`
	JobTitle string `json:"jobTitle"`
	Name     string `json:"name"`
	Email    string `json:"email"`
}

// employees slice to seed employee data.
var employees = []employee{
	{ID: "1", Name: "Chris", JobTitle: "Solutions Engineer Manager", Email: "chris@kongexample.com"},
	{ID: "2", Name: "Marco", JobTitle: "Solutions Engineer Manager", Email: "marco@kongexample.com"},
	{ID: "3", Name: "Mark", JobTitle: "Solutions Engineer", Email: "mark@kongexample.com"},
	{ID: "4", Name: "Sven", JobTitle: "Solutions Engineer", Email: "sven@kongexample.com"},
	{ID: "5", Name: "Bruno", JobTitle: "Solutions Engineer", Email: "bruno@kongexample.com"},
	{ID: "6", Name: "Hans", JobTitle: "Solutions Engineer", Email: "hans@kongexample.com"},
	{ID: "7", Name: "David", JobTitle: "Solutions Engineer", Email: "david@kongexample.com"},
	{ID: "8", Name: "Jerome", JobTitle: "Solutions Engineer", Email: "jerome@kongexample.com"},
	{ID: "9", Name: "Pierre-Alexandre", JobTitle: "Solutions Engineer", Email: "pierre-alexandre@kongexample.com"},
	{ID: "10", Name: "Deepak", JobTitle: "Solutions Engineer", Email: "deepak@kongexample.com"},
	{ID: "11", Name: "Andy", JobTitle: "Solutions Engineer", Email: "andy@kongexample.com"},
	{ID: "12", Name: "Johannes", JobTitle: "Solutions Engineer", Email: "johannes@kongexample.com"},
	{ID: "13", Name: "Ankitaa", JobTitle: "Solutions Engineer", Email: "ankitaa@kongexample.com"},
	{ID: "14", Name: "Olvier", JobTitle: "Solutions Engineer", Email: "oliver@kongexample.com"},
}

func main() {
	router := gin.Default()
	router.GET("/api/employees", getEmployees)
	router.GET("/api/employees/:id", getEmployeeByID)
	router.POST("/api/employees", postEmployees)
	router.DELETE("/api/employees/:id", deleteEmployeeByID)

	router.Run("0.0.0.0:8080")
}

// getEmployees responds with the list of all employees as JSON.
func getEmployees(c *gin.Context) {
	c.IndentedJSON(http.StatusOK, employees)
}

// getEmployeesByID locates the employee whose ID value matches the id
// parameter sent by the client, then returns that employee as a response.
func getEmployeeByID(c *gin.Context) {
	id := c.Param("id")

	// Loop over the list of employees, looking for
	// an employee whose ID value matches the parameter.
	for _, a := range employees {
		if a.ID == id {
			c.IndentedJSON(http.StatusOK, a)
			return
		}
	}
	c.IndentedJSON(http.StatusNotFound, gin.H{"message": "employee not found"})
}

// postEmployees adds an employee from JSON received in the request body.
func postEmployees(c *gin.Context) {
	var newEmployee employee

	// Call BindJSON to bind the received JSON to
	// newEmployee.
	if err := c.BindJSON(&newEmployee); err != nil {
		return
	}

	// Add the new employee to the slice.
	employees = append(employees, newEmployee)
	c.IndentedJSON(http.StatusCreated, newEmployee)
}

// deleteEmployeeByID deletes the employee whose ID value matches the id
// parameter sent by the client.
func deleteEmployeeByID(c *gin.Context) {
	id := c.Param("id")

	for i, emp := range employees {
		if emp.ID == id {
			employees = append(employees[:i], employees[i+1:]...)
			c.IndentedJSON(http.StatusOK, gin.H{"message": "Employee deleted"})
			return
		}
	}

	c.IndentedJSON(http.StatusNotFound, gin.H{"message": "Employee not found"})
}
