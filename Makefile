SRC = now_playing.d
CFG = now_playing.cfg
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
	cp $(CFG) /etc

clean:
	rm $(TARGET)
