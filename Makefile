.PHONY: test
test-e2e-tagged:
		busted --run e2e --tags=run

test-unit-tagged:
		busted --run unit --tags=run

test-unit:
		busted --run unit
		
test:
		busted --run unit
		busted --run e2e
		
