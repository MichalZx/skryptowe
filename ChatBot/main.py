import asyncio
import discord
from discord.ext import commands
import json
from datetime import datetime, timedelta
import pytz

with open("opening_hours.json", "r") as hours_file:
    opening_hours = json.load(hours_file)["items"]

with open("menu.json", "r") as menu_file:
    menu_items = json.load(menu_file)["items"]

with open("TOKEN.txt", "r") as token_file:
    TOKEN = token_file.read().strip()

menu_dict = {item["name"].lower(): item for item in menu_items}

hour_phrases = ["what are your hours?", "when are you open?", "opening hours"]
menu_phrases = ["what's on the menu?", "menu items", "what can i order?"]
order_phrases = ["i want to order", "can i have", "i'd like"]

intents = discord.Intents.default()
intents.messages = True
intents.message_content = True
bot = commands.Bot(command_prefix="!", intents=intents)
bot.remove_command('help')


def format_opening_hours():
    hours_str = []
    for day, times in opening_hours.items():
        if times["open"] == 0 and times["close"] == 0:
            hours_str.append(f"{day}: Closed")
        else:
            hours_str.append(f"{day}: {times['open']} AM - {times['close']} PM")
    return "\n".join(hours_str)


def process_order(order_items):
    confirmed = []
    unavailable = []
    additional_requests = []
    request = ""
    for item in order_items:
        found_item = next((menu_item for menu_item in menu_items if menu_item["name"].lower() in item), None)
        if found_item:
            confirmed.append(found_item)
        else:
            if "without" in item or "no" in item or "with" in item or "add" in item:
                request = f"{item}"
                continue
            elif request != "":
                additional_requests.append(f"{request} {item}")
                request = ""
            else:
                unavailable.append(item)
    return confirmed, unavailable, additional_requests


def is_restaurant_open():
    now = datetime.now(pytz.timezone("Europe/Warsaw"))
    current_day = now.strftime("%A")
    current_hour = now.hour
    if opening_hours[current_day]["open"] <= current_hour < opening_hours[current_day]["close"]:
        return True
    return False


def next_opening_time():
    now = datetime.now(pytz.timezone("Europe/Warsaw"))
    current_day_index = list(opening_hours.keys()).index(now.strftime("%A"))
    days = list(opening_hours.keys())
    for offset in range(1, 8):
        next_day_index = (current_day_index + offset) % len(days)
        next_day = days[next_day_index]
        open_hour = opening_hours[next_day]["open"]
        close_hour = opening_hours[next_day]["close"]
        if open_hour != 0 or close_hour != 0:
            next_opening_date = now + timedelta(days=offset)
            next_opening_date = next_opening_date.replace(hour=open_hour, minute=0, second=0, microsecond=0)
            return next_day, next_opening_date.strftime("%I:%M %p")
    return None, None


def calculate_preparation_time(confirmed_items):
    total_time = sum(item["preparation_time"] for item in confirmed_items)
    now = datetime.now(pytz.timezone("Europe/Warsaw"))
    available_time = now + timedelta(hours=total_time)
    return available_time.strftime("%I:%M %p")


@bot.event
async def on_ready():
    print(f"Logged in as {bot.user}")


@bot.command(name="help")
async def my_help(ctx):
    help_text = (f"Available commands\n**!help** - shows this message,\n"
                 f"**!hours** - show opening hours,\n**!menu** - show menu\n"
                 f"**!order** [meal] **and** [meal] - make an order,\n\n"
                 f"Available phrases:\n")
    for phrase in hour_phrases:
        help_text += f"**{phrase}**\n"
    for phrase in menu_phrases:
        help_text += f"**{phrase}**\n"
    for phrase in order_phrases:
        help_text += f"**{phrase}** [meal]\n"
    await ctx.send(help_text)


@bot.command(name="hours")
async def opening_hours_command(ctx):
    await ctx.send(f"Our opening hours are:\n{format_opening_hours()}")


@bot.command(name="menu")
async def menu_command(ctx):
    def convert_to_hhmm(hours):
        total_minutes = hours * 60
        hours_part = int(total_minutes // 60)
        minutes_part = int(total_minutes % 60)
        return f"{hours_part:02}:{minutes_part:02}"
    menu_text = "\n".join(
        [f"- {item['name']}: ${item['price']} (Prep Time: {convert_to_hhmm(item['preparation_time'])} hrs)" for item in
         menu_items]
    )
    await ctx.send(f"Here is our menu:\n{menu_text}")


@bot.command(name="order")
async def order_command(ctx, *args):
    if not is_restaurant_open():
        next_day, next_time = next_opening_time()
        await ctx.send(f"Sorry, the restaurant is currently closed. The next opening is on {next_day} at {next_time}.")
        return
    if not args:
        await ctx.send("Please specify the items you'd like to order.")
        return
    order_items = [item.lower() for item in args]
    confirmed, unavailable, additional_requests = process_order(order_items)
    response = []
    if confirmed:
        confirmed_text = ", ".join([item["name"] for item in confirmed])
        response.append(f"Confirmed items: {confirmed_text}")
    if unavailable:
        unavailable_text = ", ".join(unavailable)
        response.append(f"Unavailable items: {unavailable_text}")
    if confirmed and additional_requests:
        requests_text = ", ".join(additional_requests)
        response.append(f"Additional requests noted: {requests_text}")
    await ctx.send("\n".join(response))
    if confirmed:
        await ctx.send("Would you like to pick up your order or have it delivered? (Please type 'pick-up' or 'delivery')")

        def check(m):
            return m.author == ctx.author and m.channel == ctx.channel and m.content.lower() in ["pick-up", "delivery"]
        try:
            method_msg = await bot.wait_for("message", timeout=30.0, check=check)
        except asyncio.TimeoutError:
            await ctx.send("Order canceled due to no response.")
            return
        method = method_msg.content.lower()
        if method == "pick-up":
            pick_up_time = calculate_preparation_time(confirmed)
            await ctx.send(f"Your order will be ready for pick-up at {pick_up_time}. Thank you!")
        elif method == "delivery":
            await ctx.send("Please provide your delivery address:")

            def address_check(m):
                return m.author == ctx.author and m.channel == ctx.channel
            try:
                address_msg = await bot.wait_for("message", timeout=60.0, check=address_check)
            except asyncio.TimeoutError:
                await ctx.send("Order canceled due to no response.")
                return
            address = address_msg.content
            delivery_time = calculate_preparation_time(confirmed)
            await ctx.send(f"Thank you! Your order will be delivered to {address} by approximately {delivery_time}.")


@bot.event
async def on_message(message):
    if message.author == bot.user:
        return
    content = message.content.lower()
    if any(phrase in content for phrase in hour_phrases):
        await opening_hours_command(message.channel)
    elif any(phrase in content for phrase in menu_phrases):
        await menu_command(message.channel)
    elif any(phrase in content for phrase in order_phrases):
        order_request = content.replace("i want to order", "").replace("can i have", "").replace("i'd like", "").strip()
        await order_command(message.channel, *order_request.split())
    else:
        await bot.process_commands(message)

bot.run(TOKEN)
