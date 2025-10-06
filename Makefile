APP_NAME = ledger
BUILD_DIR = _build/dev
EXEC = $(BUILD_DIR)/$(APP_NAME)

.PHONY: all compile clean build escript

compile:
	mix compile

clean:
	mix clean

escript:
	mix escript.build

build: clean compile escript
	@echo "Ejecutable generado: ./$(APP_NAME)"

all: build

