test-e2e:
		busted --run e2e

test-e2e-tagged:
		busted --run e2e --tags=run

test-unit-tagged:
		busted --run unit --tags=run

test-unit:
		busted --run unit
		
.PHONY: test
test:
		busted --run unit
		busted --run e2e
		
