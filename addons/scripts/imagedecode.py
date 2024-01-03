#!/usr/bin/env python3
import logging
from datetime import datetime, timedelta
from io import BytesIO
from os import path, getenv
from pathlib import Path
from struct import unpack
from subprocess import Popen, DEVNULL
from sys import argv

logging.basicConfig(
    format="%(name)s - %(levelname)s - %(message)s",
    level=getattr(logging, getenv("SATNOGS_LOG_LEVEL", "WARNING")),
)
LOGGER = logging.getLogger("imagedecode")


class ImageDecode(object):
    def __init__(self, frame_file, norad_id=0, image_file=None):
        self.frame_file = frame_file
        self.norad_id = norad_id
        self.frames = []
        self.imagedata = BytesIO()
        if image_file is None:  # default to the same basename
            self.image_name = path.splitext(frame_file)[0]
            self.image_ts = ""
        else:
            self.image_name = image_file
            self.image_ts = datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%S")
        self.image_ext = ".jpg"
        if self.norad_id > 0:
            self.auto_decode()

    def auto_decode(self):
        # external image decoders, use return to skip internal decoders
        if self.norad_id == 43803:  # JY1Sat
            self.jy1sat_ssdv()
            return
        # internal image decoders
        self.parse_file()
        if self.norad_id in [53385, 57167]:  # Geoscan-Edelveis, StratoSat TK-1
            self.stratosat_parse_frames()
        elif self.norad_id == 54684:  # CAS-5A
            self.cas5a_process_images()
        else:
            LOGGER.debug(f"No image decoder found for {self.norad_id}")

    def parse_file(self):
        try:
            with open(self.frame_file, "r") as f:
                return self.parse_hex_file(f)
        except UnicodeDecodeError:
            with open(self.frame_file, "rb") as f:
                return self.parse_kiss_file(f)

    def parse_hex_file(self, hex_file):
        self.frames = []
        ts = datetime.utcnow()
        for row in hex_file:
            row = row.replace(" ", "").strip()
            if "|" in row:  # TODO: add auto detect on format
                row = row.split("|")[-1]
                self.frames.append((ts, row))

    def parse_kiss_file(self, infile):
        self.frames = []
        ts = datetime.utcnow()  # MUST be overwritten by timestamps in file
        for row in infile.read().split(b"\xC0"):
            if len(row) == 9 and row[0] == 9:  # timestamp frame
                ts = datetime(1970, 1, 1) + timedelta(
                    seconds=unpack(">Q", row[1:])[0] / 1000
                )
            if len(row) > 0 and row[0] == 0:  # data frame
                self.frames.append(
                    (
                        ts,
                        row[1:]
                        .replace(b"\xdb\xdc", b"\xc0")
                        .replace(b"\xdb\xdd", b"\xdb")
                        .hex(bytes_per_sep=2),
                    )
                )

    def stratosat_parse_frames(self):
        self.imagedata.seek(0)
        self.imagedata.truncate()
        cmd_match = "0200"  # default to Stratosat TK-1, 0100 Geoscan-Edelveis
        offset = 0
        hr = False
        for ts, row in self.frames:  # find start frame, memory offset, detect lr/hr
            if len(row) != 128:
                continue
            if row[16:22].upper() == "FFD8FF":
                offset = int((row[12:14] + row[10:12]), 16)
                hr = row[6:10].upper() == "2098"
                cmd_match = row[0:4].upper()
                break
        LOGGER.debug(f"Stratosat: cmd_match={cmd_match}, offset={offset}, hr={hr}")
        for ts, row in self.frames:
            if len(row) != 128:
                continue
            cmd = row[0:4]
            if hr:
                addr = int((row[14:16] + row[12:14] + row[10:12]), 16)
            else:
                addr = int((row[12:14] + row[10:12]), 16) - offset
            dlen = (int(row[4:6], 16) + 2) * 2
            payload = row[16:dlen]
            if cmd == cmd_match and addr >= 0:
                self.imagedata.seek(addr)
                self.imagedata.write(bytes.fromhex(payload))
        self.write_image()

    def cas5a_process_images(self):
        num_images = 0
        for pid in set(self.cas5a_get_photo_ids()):
            self.cas5a_parse_frames(pid)
            self.image_ext = f"_{num_images}.jpg"
            self.write_image()
            num_images += 1

    def cas5a_parse_frames(self, pid):
        self.imagedata.seek(0)
        self.imagedata.truncate()
        dlen = 240  # assumed maxed out frames to multiply by sequence number
        hlen = 32  # header length
        for ts, row in self.frames:
            if len(row) < 32:
                continue
            if pid != row[46:64] or int(row[32:34], 16) != 3:
                continue
            ftot = int(row[34:38], 16)
            fseq = int(row[38:42], 16)
            flen = int(row[42:46], 16) * 2 + hlen
            if fseq <= ftot and flen <= len(row):
                self.imagedata.seek((fseq - 1) * dlen)
                self.imagedata.write(bytes.fromhex(row[64:flen]))

    def cas5a_get_photo_ids(self):
        pids = set()
        for ts, row in self.frames:
            if len(row) < 32:
                continue
            if (
                int(row[32:34], 16) != 3
                or int(row[46:48], 16) < 22  # year
                or int(row[46:48], 16) > 25  # year
                or int(row[48:50], 16) > 12  # month
                or int(row[50:52], 16) > 31  # day
                or int(row[52:54], 16) > 24  # hour
                or int(row[54:56], 16) > 60  # minute
                or int(row[56:58], 16) > 60  # second
            ):  # sanity check
                continue
            pids.add(row[46:64])
        return pids

    def write_image(self):
        if self.imagedata.getbuffer().nbytes == 0:
            LOGGER.warning(f"No image data found in {self.frame_file}")
            return
        image_file = f"{self.image_name}{self.image_ts}{self.image_ext}"
        LOGGER.info(f"Writing image to: {image_file}")
        with open(image_file, "wb") as f:
            f.write(self.imagedata.getbuffer())

    def jy1sat_ssdv(self):
        LOGGER.info(f"Running jy1sat_ssdv for {self.norad_id}")
        Popen(
            ["jy1sat_ssdv", self.frame_file, self.image_name],
            stdout=DEVNULL,
            stderr=DEVNULL,
        )
        for f in Path(self.image_name).glob("*.ssdv"):
            f.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(argv) != 3:
        print(
            f"Usage: {argv[0]} <frame_file> <norad_id>\n"
            f"Frame file can be KISS, SatNOGS data export or GetKISS+"
        )
        exit(0)
    d = ImageDecode(argv[1], int(argv[2]))
