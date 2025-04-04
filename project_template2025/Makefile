OZC = ozc
OZENGINE = ozengine


SRC=$(wildcard *.oz)
OBJ=$(SRC:.oz=.ozf)

OZFLAGS = --nowarnunused

all: $(OBJ)

run: all
	@echo RUN main.ozf
	@$(OZENGINE) main.ozf

test: all
	@echo RUN main.ozf
	@$(OZENGINE) main.ozf --test

%.ozf: %.oz
	@echo OZC $@
	@$(OZC) $(OZFLAGS) -c $< -o $@

.PHONY: clean

clean:
	@echo rm $(OBJ)
	@rm -rf $(OBJ)
