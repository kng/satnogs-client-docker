#!/usr/bin/env python3
import logging
from base64 import b64encode
from datetime import datetime, timedelta
from json import loads, dump, JSONDecodeError
from os import getenv, unlink, kill, path
from struct import unpack
from subprocess import Popen, DEVNULL
from sys import argv

try:
    from imagedecode import ImageDecode
except ImportError:

    class ImageDecode:
        pass


logging.basicConfig(
    format="%(name)s - %(levelname)s - %(message)s",
    level=getattr(logging, getenv("SATNOGS_LOG_LEVEL", "WARNING")),
)
LOGGER = logging.getLogger("grsat")


class GrSat(object):
    def __init__(self, av):
        assert len(av) == 7, "Wrong number of arguments"
        self.cmd = av[0]
        self.obs_id = int(av[1])
        self.freq = int(av[2])
        try:
            self.tle = loads(av[3])
        except JSONDecodeError:
            self.tle = None
        self.timestamp = datetime.strptime(av[4], "%Y-%m-%dT%H-%M-%S")
        try:
            self.baud = int(float(av[5]))
        except ValueError:
            self.baud = 9600
        self.script_name = av[6]
        self.udp_port = getenv("UDP_DUMP_PORT", "57356")
        self.udp_host = getenv("UDP_DUMP_HOST", "")
        self.tmp = getenv("SATNOGS_APP_PATH", "/tmp/.satnogs")
        self.data = getenv("SATNOGS_OUTPUT_PATH", "/tmp/.satnogs/data")
        self.zmq_port = getenv("GRSAT_ZMQ_PORT", "5555")
        self.app = getenv("GRSAT_APP", "gr_satellites")
        self.keep_logs = getenv("GRSAT_KEEPLOGS", "False").lower() in [
            "true",
            "1",
            "yes",
        ]
        self.kiss_file = self.tmp + "/gr_satellites.kiss"
        self.pid_file = self.tmp + "/gr_satellites.pid"
        if self.tle is not None:
            self.norad = int(self.tle["tle2"].split(" ")[1])
            self.sat_name = self.tle["tle0"]  # may start with '0 ' or not
        else:
            self.norad = 0
            self.sat_name = ""
        self.samp_rate = self.find_samp_rate(self.baud, self.script_name)

    def worker(self):
        LOGGER.info(
            f"Observation: {self.obs_id}, Norad: {self.norad}, "
            f"Name: {self.sat_name}, Script: {self.script_name}"
        )
        if len(self.udp_host) == 0:
            LOGGER.warning("UDP_DUMP_HOST not set, no data will be sent to the demod")
        if "start" in self.cmd:
            self.start_gr_satellites()
        elif "stop" in self.cmd:
            self.stop_gr_satellites()
        else:
            LOGGER.error("Unknown command, use start or stop")

    def start_gr_satellites(self):
        LOGGER.info(f"Starting gr_satellites at {self.samp_rate} sps")
        gr_app = [
            self.app,
            str(self.norad),
            "--samp_rate",
            str(self.samp_rate),
            "--iq",
            "--udp",
            "--udp_raw",
            "--udp_port",
            str(self.udp_port),
            "--start_time",
            self.timestamp.strftime("%Y-%m-%dT%H:%M:%S"),
            "--kiss_out",
            self.kiss_file,
            "--zmq_pub",
            f"tcp://0.0.0.0:{str(self.zmq_port)}",
            "--ignore_unknown_args",
            "--use_agc",
            "--satcfg",
        ]

        LOGGER.debug(" ".join(gr_app))
        try:
            s = Popen(gr_app, stdout=DEVNULL, stderr=DEVNULL)
            with open(self.pid_file, "w") as pf:
                pf.write(str(s.pid))
        except (FileNotFoundError, TypeError):
            LOGGER.warning(f"Unable to launch {gr_app[0]}")

    def stop_gr_satellites(self):
        LOGGER.info("Stopping gr_satellites")
        try:
            with open(self.pid_file, "r") as pf:
                kill(int(pf.readline()), 15)
            unlink(self.pid_file)
        except (FileNotFoundError, ProcessLookupError, OSError):
            LOGGER.info("No gr_satellites running")

        if path.isfile(self.kiss_file):
            self.kiss_to_json()
            ImageDecode(
                self.kiss_file, self.norad, f"{self.data}/data_{str(self.obs_id)}_"
            )
            # run other scripts here
            if not self.keep_logs or path.getsize(self.kiss_file) == 0:
                unlink(self.kiss_file)

    @staticmethod  # from satnogs-open-flowgraph/satnogs_wrapper.py
    def parse_kiss_file(infile):
        ts = datetime.now()  # MUST be overwritten by timestamps in file
        for row in infile.read().split(b"\xC0"):
            if len(row) == 9 and row[0] == 9:  # timestamp frame
                ts = datetime(1970, 1, 1) + timedelta(
                    seconds=unpack(">Q", row[1:])[0] / 1000
                )
            if len(row) > 0 and row[0] == 0:  # data frame
                yield ts, row[1:].replace(b"\xdb\xdc", b"\xc0").replace(
                    b"\xdb\xdd", b"\xdb"
                )

    def kiss_to_json(self):
        with open(self.kiss_file, "rb") as kf:
            LOGGER.info("Processing kiss file")
            dp = f"{self.data}/data_{str(self.obs_id)}_"
            num_frames = 0
            for ts, frame in self.parse_kiss_file(kf):
                if len(frame) == 0:
                    continue
                datafile = f'{dp}{ts.strftime("%Y-%m-%dT%H-%M-%S_g")}'
                ext = 0
                while True:
                    if path.isfile(f"{datafile}{ext}"):
                        ext += 1
                    else:
                        datafile += str(ext)
                        break
                data = {
                    "decoder_name": "gr-satellites",
                    "pdu": b64encode(frame).decode(),
                }
                with open(datafile, "w") as df:
                    dump(data, df, default=str)
                num_frames += 1
                LOGGER.debug(f"{datafile} len {len(frame)}")
            LOGGER.info(f"Total frames: {num_frames}")

    @classmethod  # from satnogs_gr-satellites/find_samp_rate.py
    def find_samp_rate(
        cls, baudrate, script="satnogs_fm.py", sps=4, audio_samp_rate=48000
    ):
        if "_bpsk" in script:
            return cls.find_decimation(baudrate, 2, audio_samp_rate, sps) * baudrate
        elif "_fsk" in script:
            return max(4, cls.find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
        elif "_sstv" in script:
            return 4 * 4160 * 4
        elif "_qubik" in script:
            return max(4, cls.find_decimation(baudrate, 2, audio_samp_rate)) * baudrate
        elif "_apt" in script:
            return 4 * 4160 * 4
        else:  # cw, fm, afsk, etc...
            return audio_samp_rate

    @staticmethod  # from gr-satnogs/python/utils.py
    def find_decimation(baudrate, min_decimation=4, audio_samp_rate=48e3, multiple=2):
        while min_decimation * baudrate < audio_samp_rate:
            min_decimation = min_decimation + 1
        if min_decimation % multiple:
            min_decimation = min_decimation + multiple - min_decimation % multiple
        return min_decimation


if __name__ == "__main__":
    if len(argv) != 8:
        LOGGER.error(
            "Wrong number of arguments, expected: "
            "<start|stop> {{ID}} {{FREQ}} {{TLE}} {{TIMESTAMP}} {{BAUD}} {{SCRIPT_NAME}}"
        )
        exit(0)
    gr = GrSat(argv[1:])
    gr.worker()
