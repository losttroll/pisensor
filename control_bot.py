import os
import random
import discord
import json
from ptzcontrols import ptz
from dotenv import load_dotenv

load_dotenv()

intents = discord.Intents.default()
intents.message_content = True
client = discord.Client(intents=intents)

@client.event
async def on_ready():
    print(f"{client.user} is connected")
    return

@client.event
async def on_message(message):
    discord_token = os.environ["DISCORD_TOKEN"]
    mode = os.environ["DISCORD_MODE"]

    if mode == "dev":
        op = "?"
    else:
        op = "!"

    # we do not want the bot to reply to itself
    if message.author == client.user:
        return
    print(message.author)
    print(message.content)
    print(f"[*] Message Received: {message.content}")

    response = "Message received, but not response was given from function"

    if message.content.startswith(op):
        command = message.content[1:]

        commands = command.split(" ")
        command = commands[0]

        print(f"[*] Command: {command}")

        if command == "ptz":
            print("[*] Calling pan function")
            count = 1
            response = ptz(commands[2], count=count)

        elif command == "test":
            response = "Command prompt successful"
            #if len(commands) == 4:
            #    count = commands[3]
            #response = ptz(commands[2], count=count)

        await message.channel.send(response)
    else:
        print("[*] Message received, but did not include prefix")

discord_token = os.environ["DISCORD_TOKEN"]
client.run(discord_token)
