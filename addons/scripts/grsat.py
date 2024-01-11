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
    HAS_IMAGEDECODE = False

    class ImageDecode:
        pass

else:
    HAS_IMAGEDECODE = True

logging.basicConfig(
    format="%(name)s - %(levelname)s - %(message)s",
    level=getattr(
        logging, getenv("GRSAT_LOG_LEVEL", getenv("SATNOGS_LOG_LEVEL", "WARNING"))
    ),
)
LOGGER = logging.getLogger("grsat")


class GrSat(object):
    def __init__(
        self,
        cmd="",
        obs_id="0",
        freq="0",
        tle="",
        timestamp="",
        baud="",
        script="",
    ):
        self.cmd = cmd
        try:
            self.obs_id = int(obs_id)
        except ValueError:
            self.obs_id = 0
        try:
            self.freq = float(freq)
        except ValueError:
            self.freq = 0
        try:
            self.tle = loads(tle)
        except JSONDecodeError:
            self.tle = None
        try:
            self.timestamp = datetime.strptime(timestamp, "%Y-%m-%dT%H-%M-%S")
        except ValueError:
            self.timestamp = datetime.utcnow()
        self.baud = baud  # can be "None"
        self.script_name = script

        self.udp_port = getenv("UDP_DUMP_PORT", "57356")
        self.udp_host = getenv("UDP_DUMP_HOST", "")
        self.station_id = getenv("SATNOGS_STATION_ID", "0")
        self.tmp = getenv("SATNOGS_APP_PATH", "/tmp/.satnogs")
        self.data = getenv("SATNOGS_OUTPUT_PATH", "/tmp/.satnogs/data")
        try:
            self.zmq_port = int(getenv("GRSAT_ZMQ_PORT"))
        except (ValueError, TypeError):
            self.zmq_port = 0
        self.app = getenv("GRSAT_APP", "gr_satellites")
        self.keep_logs = getenv("GRSAT_KEEPLOGS", "False").lower() in [
            "true",
            "1",
            "yes",
        ]

        self.kiss_file = f"{self.tmp}/grsat_{self.obs_id}.kiss"
        self.log_file = f"{self.tmp}/grsat_{self.obs_id}.log"
        self.pid_file = f"{self.tmp}/grsat_{self.station_id}.pid"
        if self.tle is not None:
            self.norad = int(self.tle["tle2"].split()[1])
            self.sat_name = self.tle["tle0"]  # may start with '0 ' or not
        else:
            self.norad = 0
            self.sat_name = ""
        self.samp_rate = self.find_samp_rate(self.baud, self.script_name)

    def main(self):
        LOGGER.info(
            f"Observation: {self.obs_id}, Norad: {self.norad}, Name: {self.sat_name}, "
            f"Script: {self.script_name}, Baud: {self.baud}, Freq: {self.freq/1e6:.3f} MHz"
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
            "--ignore_unknown_args",
            "--use_agc",
            "--satcfg",
        ]
        if 0 < self.zmq_port <= 65535:
            gr_app.extend(["--zmq_pub", f"tcp://0.0.0.0:{str(self.zmq_port)}"])

        LOGGER.debug(" ".join(gr_app))
        try:
            if self.keep_logs:
                logfile = open(self.log_file, "w")
            else:
                logfile = DEVNULL
            s = Popen(gr_app, stdout=logfile, stderr=logfile)
            with open(self.pid_file, "w") as pf:
                pf.write(str(s.pid))
        except (FileNotFoundError, TypeError, OSError) as e:
            LOGGER.warning(f"Unable to launch {self.app}: {e}")

    def stop_gr_satellites(self):
        try:
            with open(self.pid_file, "r") as pf:
                kill(int(pf.readline()), 15)
            unlink(self.pid_file)
            LOGGER.info("Stopped gr_satellites")
        except (FileNotFoundError, ProcessLookupError, OSError):
            LOGGER.info("No gr_satellites running")

        if path.isfile(self.kiss_file) and path.getsize(self.kiss_file) > 0:
            self.kiss_to_json()
            if HAS_IMAGEDECODE:
                ImageDecode(
                    self.kiss_file, self.norad, f"{self.data}/data_{str(self.obs_id)}_"
                )
            # run other scripts here
            if not self.keep_logs:
                unlink(self.kiss_file)
        elif path.isfile(self.kiss_file):
            unlink(self.kiss_file)

        if path.isfile(self.log_file) and (
            not self.keep_logs or path.getsize(self.log_file) == 0
        ):
            unlink(self.log_file)

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
    def find_samp_rate(cls, baudrate, script="", sps=4, audio_samp_rate=48000):
        try:
            baudrate = int(float(baudrate))
        except ValueError:
            baudrate = 9600
        if baudrate < 1:
            baudrate = 9600

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
        elif "_ssb" in script:
            return cls.find_decimation(baudrate, 2, audio_samp_rate, sps) * baudrate
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
    GrSat(argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], argv[7]).main()
