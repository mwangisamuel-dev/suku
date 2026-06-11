import qrcode
img = qrcode.make("192.168.1.102:42319")
img.save("assets/adb_pair_qr.png")
print("SAVED")
