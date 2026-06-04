# Download dependencies under ./dependencies
init-standalone:
	west init -l config --mf west-standalone.yml
	west update --narrow
	git -C dependencies/zmk-feature-default-layer diff --quiet && git -C dependencies/zmk-feature-default-layer apply ../../patches/zmk-feature-default-layer.patch || true
	git -C dependencies/zmk-module-runtime-input-processor diff --quiet && git -C dependencies/zmk-module-runtime-input-processor apply ../../patches/zmk-module-runtime-input-processor.patch || true
	git -C dependencies/zmk-module-battery-history diff --quiet && git -C dependencies/zmk-module-battery-history apply ../../patches/zmk-module-battery-history.patch || true
	git -C dependencies/zmk-module-ble-management diff --quiet && git -C dependencies/zmk-module-ble-management apply ../../patches/zmk-module-ble-management.patch || true
	git -C dependencies/zmk diff --quiet && git -C dependencies/zmk apply ../../patches/zmk.patch || true
	west zephyr-export

# Download dependencies under ../
init-workspace:
	west init -l . --mf config/west.yml
	west update --narrow
	west zephyr-export

build-all:
	west zmk-build -d ./build -q

debug-all:
	west zmk-build -S zmk-usb-logging
