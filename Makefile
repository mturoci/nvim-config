.PHONY: test
test-e2e-tagged:
		busted --run e2e --tags=run

test:
		busted --run unit
		busted --run e2e
		
