# Convenience makefile to build the dev env and run common commands

# Run the server
.PHONY: run
run:
	@go run main.go

# Run tests
.PHONY: test
test:
	@go test -v ./...

# Build the elm app
.PHONY: elm
elm:
	@elm make frontend/Index.elm --output static/index.js
