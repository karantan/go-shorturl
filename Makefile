# Convenience makefile to build the dev env and run common commands

# Run the server
.PHONY: run
run:
	@go run main.go

# Build the elm app
.PHONY: elm
elm:
	@elm make src/Main.elm --output static/elm.js