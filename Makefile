GODOT ?= /Applications/Godot.app/Contents/MacOS/Godot
GODOT_LOG ?= /tmp/elderscourage-godot.log
DATA_DIR ?= ./game/data
LOOT_LEVEL ?= 5
LOOT_RARITY ?= relic
LOOT_SEED ?= 42

.PHONY: help test validate acceptance loot godot-check run check fmt

help:
	@echo "Common commands:"
	@echo "  make test        Run Go tests"
	@echo "  make validate    Validate game data"
	@echo "  make acceptance  Print static acceptance report"
	@echo "  make loot        Generate deterministic loot sample"
	@echo "  make godot-check Verify Godot project loads headlessly"
	@echo "  make run         Run the Godot prototype"
	@echo "  make check       Run Go tests, validation, report, and Godot headless load"
	@echo "  make fmt         Format Go files"

test:
	go test ./...

validate:
	go run ./cmd/elders validate-data $(DATA_DIR)

acceptance:
	go run ./cmd/elders acceptance-report $(DATA_DIR)

loot:
	go run ./cmd/elders generate-loot --level $(LOOT_LEVEL) --rarity $(LOOT_RARITY) --seed $(LOOT_SEED) --data $(DATA_DIR)

godot-check:
	$(GODOT) --headless --log-file $(GODOT_LOG) --path game --quit

run:
	$(GODOT) --path game

check: test validate acceptance godot-check

fmt:
	gofmt -w cmd internal
