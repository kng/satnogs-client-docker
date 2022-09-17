#!/var/lib/satnogs/bin/python3
import sys
from satnogsclient.waterfall import EmptyArrayError, Waterfall

if len(sys.argv) > 1:
    try:
        waterfall = Waterfall('{}.dat'.format(sys.argv[1]))
        waterfall.plot('{}.png'.format(sys.argv[1]))
    except FileNotFoundError:
         print('No waterfall data file found')
    except (EmptyArrayError, IndexError):
         print('Waterfall data array is empty')

else:
    print("useage: {0} <file prefix>\nexample: {0} test\nwill read test.dat and create test.png".format(sys.argv[0]))
