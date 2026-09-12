add_executable(main
	AboutMenuPage.cpp
	ButtonTask.cpp
	ClocksMenuPage.cpp
	DemoCLISessionContext.cpp
	DisplayTask.cpp
	MenuPageHandler.cpp
	MenuSystem.cpp
	NRZMenuPage.cpp
	PAM3MenuPage.cpp
	RGBMenuPage.cpp
	RGBTask.cpp
	TransceiverMenuPage.cpp

	globals.cpp
	Init.cpp
	vectors.cpp)

target_link_options(main
	PUBLIC "-ffunction-sections"
	PUBLIC "-Wl,--gc-sections"
	PUBLIC "-Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/firmware.ld"
	PUBLIC "-L${PROJECT_ROOT}/stm32-cpp/devices/link/"
	PUBLIC "-L${CMAKE_CURRENT_SOURCE_DIR}/..")

target_link_libraries(main
	bsp
	common-embedded-platform-boilerplate-h750
	common-embedded-platform-cli
	common-embedded-platform-core
	common-embedded-platform-drivers
	common-embedded-platform-fpga
	embedded-cli
	embedded-utils
	microkvs
	stm32-cpp
	)

# Calculate flash usage and generate binary file
common_postbuild(main)
