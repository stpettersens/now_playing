SRC = now_playing.d
CFG_PLAYERS = players.cfg
CFG_FILTERS = filters.cfg
CFG_DIR = /etc/now_playing
TARGET = now_playing

make:
	ldc2 $(SRC)
	rm $(TARGET).o
	strip $(TARGET)

compress:
	upx -9 $(TARGET)

install:
	@echo "Please run as doas/sudo."
	cp $(TARGET) /usr/local/bin
	mkdir -p $(CFG_DIR)
	cp $(CFG_PLAYERS) $(CFG_DIR)
	cp $(CFG_FILTERS) $(CFG_DIR)

clean:
	rm $(TARGET)
