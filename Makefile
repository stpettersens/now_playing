SRC = now_playing.d
TARGET = now_playing

make:
	ldc2 $(SRC)
	rm $(TARGET).o
	strip $(TARGET)
	upx -9 $(TARGET)

install:
	@echo "Please run as doas/sudo."
	cp rb_get_song /usr/local/bin
	chmod +x /usr/local/bin/rb_get_song
	cp $(TARGET)  /usr/local/bin

clean:
	rm $(TARGET)
