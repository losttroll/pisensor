# Complete Project Details: https://RandomNerdTutorials.com/raspberry-pi-bme280-data-logger/

import smbus2
import bme280
import os
import datetime
import time
import json
from dotenv import load_dotenv

load_dotenv()

def fileOutput():
    sensor = os.environ["PS_SENSOR_NAME"]
    outpath = os.environ["PS_READING_OUTDIR"]
    writefile = os.environ["PS_WRITE_FILE"]

    if writefile == "False":
        writefile = False
    elif writefile == "True":
        writefile = True

    ts = datetime.datetime.now().strftime("%Y%m%dT%H%M%S")

    filename = f"{sensor}.{ts}"
    results = getReadings()
    print("Reading Results")
    for e in results:
        print(e, results[e])


    if writefile == False:
        print("[!] PS_WRITE_FILE set to false, not writing export file")
    with open(f'{outpath}/{filename}.weatherdata', 'w') as f:
        json.dump(results, f)
    return

def getReadings():
    # BME280 sensor address (default address)
    address = 0x76

    # Initialize I2C bus
    bus = smbus2.SMBus(1)
    time.sleep(1)
    # Load calibration parameters
    calibration_params = bme280.load_calibration_params(bus, address)
    try:
        calibration_params = bme280.load_calibration_params(bus, address)
    except Exception as e:
        print(f"[!] Unable to detect bme280 at address: {int(address)}")
        print(f"    run the commmand: sudo i2cdetect -y 1")
        print(e)
        return {}

    # create a variable to control the while loop
    running = True

    # Check if the file exists before opening it in 'a' mode (append mode)
    if os.environ["PS_LOG_READINGS"] == True:
        file_exists = os.path.isfile('sensor_readings_bme280.txt')
        file = open('sensor_readings_bme280.txt', 'a')

        # Write the header to the file if the file does not exist
        if not file_exists:
            file.write('Time and Date, temperature (ºC), temperature (ºF), humidity (%), pressure (hPa)\n')

    # Read sensor data
    data = bme280.sample(bus, address, calibration_params)

    # Extract temperature, pressure, humidity, and corresponding timestamp
    temperature_celsius = data.temperature
    humidity = data.humidity
    pressure = data.pressure
    timestamp = data.timestamp

    # Adjust timezone
    # Define the timezone you want to use (list of timezones: https://gist.github.com/mjrulesamrat/0c1f7de951d3c508fb3a20b4b0b33a98)
    #desired_timezone = pytz.timezone('MST')  # Replace with your desired timezone

    # Convert the datetime to the desired timezone
    #timestamp_tz = timestamp.replace(tzinfo=pytz.utc).astimezone(desired_timezone)

    # Convert temperature to Fahrenheit
    temperature_fahrenheit = (temperature_celsius * 9/5) + 32

    # Print the readings
    #print(timestamp_tz.strftime('%H:%M:%S %d/%m/%Y') + " Temp={0:0.1f}ºC, Temp={1:0.1f}ºF, Humidity={2:0.1f}%, Pressure={3:0.2f}hPa".format(temperature_celsius, temperature_fahrenheit, humidity, pressure))
    data = {"timestamp" : datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            "temp" : round(temperature_fahrenheit, 2),
            "humidity" : round(humidity, 2),
            "pressure" : round(pressure, 2),
            "sensor"    : os.environ["PS_SENSOR_NAME"]
}
    # Save time, date, temperature, humidity, and pressure in .txt file
    #file.write(timestamp_tz.strftime('%H:%M:%S %d/%m/%Y') + ', {:.2f}, {:.2f}, {:.2f}, {:.2f}\n'.format(temperature_celsius, temperature_fahrenheit, humidity, round(pressure, 2)))
    #time.sleep(10)

    return data

def checkVariables():
    for var in ["PS_SENSOR_NAME", "PS_SENSOR_OUTDIR", "PS_LOG_READINGS"]:
        if not os.eviron[var]:
            print(f"[!] Missing variable, add {var} to .env and re-run")

def main():
    results = getReadings()
    for e in results:
        print(f"{e}: {results[e]}")
    return

if __name__ == "__main__":
    #main()
    fileOutput()
