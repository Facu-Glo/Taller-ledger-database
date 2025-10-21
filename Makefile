APP_NAME = ledger
BUILD_DIR = _build/dev
EXEC = $(BUILD_DIR)/$(APP_NAME)

.PHONY: all compile clean build escript db stop test create

compile:
	mix compile

clean:
	mix clean

escript:
	mix escript.build

db:
	docker-compose up -d

stop: 
	docker-compose down
	
test:
	mix coveralls

create:
	mix deps.get
	docker-compose up -d
	mix ecto.migrate
	mix compile
	mix escript.build

build: clean compile escript
	@echo "Ejecutable generado: ./$(APP_NAME)"

all: build


