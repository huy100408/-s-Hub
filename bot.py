# -------- EMPIRE BOT - COMPLETE REDESIGN WITH UI SYSTEMS --------

import subprocess, sys
def pip_install(package): subprocess.check_call([sys.executable, "-m", "pip", "install", package])
try:
    import discord
    from discord.ext import commands, tasks
    from discord import app_commands
except ImportError:
    pip_install("discord.py>=2.3.2")
    import discord
    from discord.ext import commands, tasks
    from discord import app_commands

import os, json, random, asyncio, datetime
from discord.ui import Button, View, Select, Modal, TextInput
from discord import Interaction, Embed, ButtonStyle, SelectOption

TOKEN = "MTM5MjY3MzgyMTcwNTc2OTE5MQ.GI2ttJ.-VcrviYTe32Z4NZU8TEGD4ruETmJByISwT-od8"
ADMIN_IDS = [1355906051442216981, 878991087920902274]

intents = discord.Intents.default()
intents.guilds = True
intents.members = True
intents.message_content = True

bot = commands.Bot(command_prefix="!", intents=intents)
tree = bot.tree

DATA_FILE = "empire_data.json"

if not os.path.exists(DATA_FILE):
    with open(DATA_FILE, "w") as f: json.dump({}, f)

def load_data():
    with open(DATA_FILE, "r") as f: return json.load(f)

def save_data(data):
    with open(DATA_FILE, "w") as f: json.dump(data, f, indent=2)

data = load_data()

def get_user_data(user_id):
    uid = str(user_id)
    if uid not in data:
        data[uid] = {
            "xp": 0,
            "level": 1,
            "rank": "Peasant",
            "zolar": 100,
            "inventory": [],
            "power": 100,
            "equipment": {"weapon": None, "armor": None, "accessory": None},
            "exploration_energy": 100,
            "exploration_rewards": [],
            "redeemed_codes": [],
            "stats": {"wins": 0, "losses": 0, "exploration_count": 0},
            "banned": False
        }
        save_data(data)
    else:
        # Ensure all required keys exist for existing users
        user_data = data[uid]
        if "exploration_energy" not in user_data:
            user_data["exploration_energy"] = 100
        if "exploration_rewards" not in user_data:
            user_data["exploration_rewards"] = []
        if "redeemed_codes" not in user_data:
            user_data["redeemed_codes"] = []
        if "stats" not in user_data:
            user_data["stats"] = {"wins": 0, "losses": 0, "exploration_count": 0}
        if "banned" not in user_data:
            user_data["banned"] = False
        if "equipment" not in user_data:
            user_data["equipment"] = {"weapon": None, "armor": None, "accessory": None}
        if "power" not in user_data:
            user_data["power"] = 100
        if "inventory" not in user_data:
            user_data["inventory"] = []
        save_data(data)
    return data[uid]

def check_user_ban(user_id):
    user_data = get_user_data(user_id)
    return user_data.get("banned", False)

RANK_SYSTEM = [
    {"level": 1, "name": "Peasant", "power_bonus": 0},
    {"level": 5, "name": "Knight", "power_bonus": 50},
    {"level": 10, "name": "Baron", "power_bonus": 150},
    {"level": 20, "name": "Duke", "power_bonus": 300},
    {"level": 30, "name": "Prince", "power_bonus": 500},
    {"level": 50, "name": "King", "power_bonus": 1000},
]

def get_rank_by_level(level):
    current = {"name": "Peasant", "power_bonus": 0}
    for r in RANK_SYSTEM:
        if level >= r["level"]:
            current = r
    return current

def is_admin(user_id): return int(user_id) in ADMIN_IDS

@bot.event
async def on_ready():
    print(f"🤖 Bot is online as {bot.user}")
    try:
        # Sync commands globally (don't clear them first)
        synced = await tree.sync()
        print(f"✅ Synced {len(synced)} global commands")

        # Also sync to all guilds the bot is in (for faster testing)
        for guild in bot.guilds:
            try:
                guild_synced = await tree.sync(guild=guild)
                print(f"✅ Synced {len(guild_synced)} commands to guild: {guild.name}")
            except Exception as e:
                print(f"❌ Failed to sync to guild {guild.name}: {e}")

        print("🔄 All commands synced and updated")

    except Exception as e:
        print(f"❌ Error during command sync: {e}")

# -------- XP SYSTEM --------
XP_PER_MESSAGE = 10

async def add_xp(user_id: int, amount: int):
    user_data = get_user_data(user_id)
    user_data["xp"] += amount
    level_up_xp = 100 * user_data["level"]
    leveled_up = False

    # Ensure power key exists for older users
    if "power" not in user_data:
        user_data["power"] = 100

    while user_data["xp"] >= level_up_xp:
        user_data["xp"] -= level_up_xp
        user_data["level"] += 1
        rank_info = get_rank_by_level(user_data["level"])
        user_data["rank"] = rank_info["name"]
        user_data["power"] += rank_info["power_bonus"]
        leveled_up = True
        level_up_xp = 100 * user_data["level"]

    save_data(data)
    return leveled_up

@bot.event
async def on_message(message):
    if message.author.bot:
        return

    try:
        if check_user_ban(message.author.id):
            return

        leveled = await add_xp(message.author.id, XP_PER_MESSAGE)
        if leveled:
            try:
                user_data = get_user_data(message.author.id)
                await message.channel.send(
                    f"🎉 {message.author.mention} leveled up to **{user_data['level']}** and is now a **{user_data['rank']}**! Power increased!"
                )
            except Exception:
                pass
    except Exception:
        pass

    await bot.process_commands(message)

# -------- MAIN SHOP UI SYSTEM --------
class ShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Choose a shop category...",
        options=[
            SelectOption(label="🏪 Items", description="Buy weapons, armor, and consumables", value="items"),
            SelectOption(label="👑 Ranks", description="Purchase higher ranks", value="ranks"),
            SelectOption(label="⚡ Power Boosts", description="Increase your power level", value="power"),
            SelectOption(label="🔋 Energy Refills", description="Restore exploration energy", value="energy"),
            SelectOption(label="💎 Premium Items", description="Exclusive rare items", value="premium")
        ]
    )
    async def shop_category(self, interaction: Interaction, select: Select):
        category = select.values[0]

        if category == "items":
            view = ItemShopView(self.user_id)
        elif category == "ranks":
            view = RankShopView(self.user_id)
        elif category == "power":
            view = PowerShopView(self.user_id)
        elif category == "energy":
            view = EnergyShopView(self.user_id)
        elif category == "premium":
            view = PremiumShopView(self.user_id)

        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="🏪 Empire Shop", description="Select a category to browse items!", color=discord.Color.blue())
        embed.add_field(name="Categories Available:", value="🏪 Items\n👑 Ranks\n⚡ Power Boosts\n🔋 Energy Refills\n💎 Premium Items", inline=False)
        return embed

class ItemShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id
        self.items = {
            "Iron Sword": {"price": 200, "type": "weapon", "power": 50},
            "Steel Sword": {"price": 500, "type": "weapon", "power": 100},
            "Dragon Blade": {"price": 1500, "type": "weapon", "power": 300},
            "Leather Armor": {"price": 150, "type": "armor", "power": 30},
            "Chain Mail": {"price": 400, "type": "armor", "power": 80},
            "Dragon Scale": {"price": 1200, "type": "armor", "power": 250},
            "Health Potion": {"price": 50, "type": "consumable", "effect": "heal"},
            "Power Elixir": {"price": 100, "type": "consumable", "effect": "power_boost"}
        }

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Select an item to buy...",
        options=[
            SelectOption(label="Iron Sword", description="Power +50 | 200 Zolar", emoji="⚔️", value="Iron Sword"),
            SelectOption(label="Steel Sword", description="Power +100 | 500 Zolar", emoji="⚔️", value="Steel Sword"),
            SelectOption(label="Dragon Blade", description="Power +300 | 1500 Zolar", emoji="🗡️", value="Dragon Blade"),
            SelectOption(label="Leather Armor", description="Power +30 | 150 Zolar", emoji="🛡️", value="Leather Armor"),
            SelectOption(label="Chain Mail", description="Power +80 | 400 Zolar", emoji="🛡️", value="Chain Mail")
        ]
    )
    async def buy_item(self, interaction: Interaction, select: Select):
        item_name = select.values[0]
        item = self.items[item_name]
        user_data = get_user_data(self.user_id)

        if user_data["zolar"] < item["price"]:
            await interaction.response.send_message(f"❌ You need {item['price']} Zolar but only have {user_data['zolar']}!", ephemeral=True)
            return

        user_data["zolar"] -= item["price"]
        user_data["inventory"].append(item_name)

        if item["type"] in ["weapon", "armor"]:
            user_data["power"] += item["power"]
            user_data["equipment"][item["type"]] = item_name

        save_data(data)

        embed = Embed(
            title="✅ Purchase Successful!",
            description=f"You bought **{item_name}** for {item['price']} Zolar!",
            color=discord.Color.green()
        )
        if item["type"] in ["weapon", "armor"]:
            embed.add_field(name="Power Increased!", value=f"+{item['power']} Power", inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Shop", style=ButtonStyle.gray)
    async def back_to_shop(self, interaction: Interaction, button: Button):
        view = ShopView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="🏪 Item Shop", description="Purchase weapons, armor, and consumables!", color=discord.Color.blue())

        weapons_text = "⚔️ **Weapons**\n"
        armor_text = "🛡️ **Armor**\n"
        consumables_text = "🧪 **Consumables**\n"

        for name, item in self.items.items():
            if item["type"] == "weapon":
                weapons_text += f"{name} - {item['price']} Zolar (+{item['power']} Power)\n"
            elif item["type"] == "armor":
                armor_text += f"{name} - {item['price']} Zolar (+{item['power']} Power)\n"
            elif item["type"] == "consumable":
                consumables_text += f"{name} - {item['price']} Zolar\n"

        embed.add_field(name=weapons_text, value="\u200b", inline=False)
        embed.add_field(name=armor_text, value="\u200b", inline=False)
        embed.add_field(name=consumables_text, value="\u200b", inline=False)
        return embed

class RankShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Select a rank to purchase...",
        options=[
            SelectOption(label="Knight", description="Level 5 | 1000 Zolar | +50 Power", emoji="🛡️", value="Knight"),
            SelectOption(label="Baron", description="Level 10 | 2500 Zolar | +150 Power", emoji="👑", value="Baron"),
            SelectOption(label="Duke", description="Level 20 | 5000 Zolar | +300 Power", emoji="🏰", value="Duke"),
            SelectOption(label="Prince", description="Level 30 | 10000 Zolar | +500 Power", emoji="👑", value="Prince"),
            SelectOption(label="King", description="Level 50 | 25000 Zolar | +1000 Power", emoji="👑", value="King")
        ]
    )
    async def buy_rank(self, interaction: Interaction, select: Select):
        rank_name = select.values[0]
        user_data = get_user_data(self.user_id)

        rank_prices = {"Knight": 1000, "Baron": 2500, "Duke": 5000, "Prince": 10000, "King": 25000}
        rank_levels = {"Knight": 5, "Baron": 10, "Duke": 20, "Prince": 30, "King": 50}

        price = rank_prices[rank_name]
        required_level = rank_levels[rank_name]

        if user_data["level"] < required_level:
            await interaction.response.send_message(f"❌ You need to be level {required_level} to buy {rank_name}!", ephemeral=True)
            return

        if user_data["zolar"] < price:
            await interaction.response.send_message(f"❌ You need {price} Zolar but only have {user_data['zolar']}!", ephemeral=True)
            return

        user_data["zolar"] -= price
        user_data["rank"] = rank_name
        rank_info = get_rank_by_level(required_level)
        user_data["power"] += rank_info["power_bonus"]
        save_data(data)

        embed = Embed(
            title="👑 Rank Upgrade Successful!",
            description=f"You are now a **{rank_name}**!",
            color=discord.Color.gold()
        )
        embed.add_field(name="Power Bonus", value=f"+{rank_info['power_bonus']} Power", inline=False)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Shop", style=ButtonStyle.gray)
    async def back_to_shop(self, interaction: Interaction, button: Button):
        view = ShopView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="👑 Rank Shop", description="Purchase higher ranks for power and prestige!", color=discord.Color.gold())
        embed.add_field(name="Available Ranks:", value="🛡️ Knight (Lv.5) - 1000 Zolar\n👑 Baron (Lv.10) - 2500 Zolar\n🏰 Duke (Lv.20) - 5000 Zolar\n👑 Prince (Lv.30) - 10000 Zolar\n👑 King (Lv.50) - 25000 Zolar", inline=False)
        return embed

class PowerShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Select a power boost...",
        options=[
            SelectOption(label="Small Power Boost", description="+25 Power | 100 Zolar", emoji="⚡", value="small"),
            SelectOption(label="Medium Power Boost", description="+75 Power | 250 Zolar", emoji="⚡", value="medium"),
            SelectOption(label="Large Power Boost", description="+150 Power | 500 Zolar", emoji="⚡", value="large"),
            SelectOption(label="Mega Power Boost", description="+300 Power | 1000 Zolar", emoji="⚡", value="mega")
        ]
    )
    async def buy_power(self, interaction: Interaction, select: Select):
        boost_type = select.values[0]
        user_data = get_user_data(self.user_id)

        boosts = {
            "small": {"power": 25, "price": 100},
            "medium": {"power": 75, "price": 250},
            "large": {"power": 150, "price": 500},
            "mega": {"power": 300, "price": 1000}
        }

        boost = boosts[boost_type]

        if user_data["zolar"] < boost["price"]:
            await interaction.response.send_message(f"❌ You need {boost['price']} Zolar but only have {user_data['zolar']}!", ephemeral=True)
            return

        user_data["zolar"] -= boost["price"]
        user_data["power"] += boost["power"]
        save_data(data)

        embed = Embed(
            title="⚡ Power Boost Successful!",
            description=f"Your power increased by **{boost['power']}**!",
            color=discord.Color.yellow()
        )
        embed.add_field(name="New Power Level", value=f"{user_data['power']}", inline=False)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Shop", style=ButtonStyle.gray)
    async def back_to_shop(self, interaction: Interaction, button: Button):
        view = ShopView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="⚡ Power Shop", description="Boost your power level!", color=discord.Color.yellow())
        embed.add_field(name="Power Boosts:", value="⚡ Small (+25) - 100 Zolar\n⚡ Medium (+75) - 250 Zolar\n⚡ Large (+150) - 500 Zolar\n⚡ Mega (+300) - 1000 Zolar", inline=False)
        return embed

class EnergyShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="🔋 Refill Energy (50 Zolar)", style=ButtonStyle.green)
    async def refill_energy(self, interaction: Interaction, button: Button):
        user_data = get_user_data(self.user_id)

        if user_data["zolar"] < 50:
            await interaction.response.send_message("❌ You need 50 Zolar to refill energy!", ephemeral=True)
            return

        if user_data["exploration_energy"] >= 100:
            await interaction.response.send_message("❌ Your energy is already full!", ephemeral=True)
            return

        user_data["zolar"] -= 50
        user_data["exploration_energy"] = 100
        save_data(data)

        embed = Embed(title="🔋 Energy Refilled!", description="Your exploration energy is now full!", color=discord.Color.green())
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Shop", style=ButtonStyle.gray)
    async def back_to_shop(self, interaction: Interaction, button: Button):
        view = ShopView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        user_data = get_user_data(self.user_id)
        embed = Embed(title="🔋 Energy Shop", description="Restore your exploration energy!", color=discord.Color.green())
        embed.add_field(name="Current Energy:", value=f"{user_data['exploration_energy']}/100", inline=False)
        embed.add_field(name="Refill Cost:", value="50 Zolar", inline=False)
        return embed

class PremiumShopView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Select a premium item...",
        options=[
            SelectOption(label="Legendary Sword", description="+500 Power | 5000 Zolar", emoji="🗡️", value="legendary_sword"),
            SelectOption(label="Divine Armor", description="+400 Power | 4000 Zolar", emoji="🛡️", value="divine_armor"),
            SelectOption(label="Crown of Kings", description="+1000 Power | 10000 Zolar", emoji="👑", value="crown"),
            SelectOption(label="Dragon Pet", description="Companion | 15000 Zolar", emoji="🐉", value="dragon_pet")
        ]
    )
    async def buy_premium(self, interaction: Interaction, select: Select):
        item_key = select.values[0]
        user_data = get_user_data(self.user_id)

        items = {
            "legendary_sword": {"name": "Legendary Sword", "power": 500, "price": 5000},
            "divine_armor": {"name": "Divine Armor", "power": 400, "price": 4000},
            "crown": {"name": "Crown of Kings", "power": 1000, "price": 10000},
            "dragon_pet": {"name": "Dragon Pet", "power": 200, "price": 15000}
        }

        item = items[item_key]

        if user_data["zolar"] < item["price"]:
            await interaction.response.send_message(f"❌ You need {item['price']} Zolar but only have {user_data['zolar']}!", ephemeral=True)
            return

        user_data["zolar"] -= item["price"]
        user_data["inventory"].append(item["name"])
        user_data["power"] += item["power"]
        save_data(data)

        embed = Embed(
            title="💎 Premium Purchase!",
            description=f"You acquired the **{item['name']}**!",
            color=discord.Color.purple()
        )
        embed.add_field(name="Power Gained", value=f"+{item['power']} Power", inline=False)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Shop", style=ButtonStyle.gray)
    async def back_to_shop(self, interaction: Interaction, button: Button):
        view = ShopView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="💎 Premium Shop", description="Exclusive legendary items!", color=discord.Color.purple())
        embed.add_field(name="Premium Items:", value="🗡️ Legendary Sword (+500 Power) - 5000 Zolar\n🛡️ Divine Armor (+400 Power) - 4000 Zolar\n👑 Crown of Kings (+1000 Power) - 10000 Zolar\n🐉 Dragon Pet (+200 Power) - 15000 Zolar", inline=False)
        return embed

# -------- EXPLORATION SYSTEM --------
class ExplorationView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Choose exploration area...",
        options=[
            SelectOption(label="🌲 Forest", description="Low risk, small rewards | 10 Energy", emoji="🌲", value="forest"),
            SelectOption(label="🏔️ Mountains", description="Medium risk, good rewards | 20 Energy", emoji="🏔️", value="mountains"),
            SelectOption(label="🏜️ Desert", description="High risk, great rewards | 30 Energy", emoji="🏜️", value="desert"),
            SelectOption(label="🌋 Volcano", description="Extreme risk, legendary rewards | 50 Energy", emoji="🌋", value="volcano")
        ]
    )
    async def explore_area(self, interaction: Interaction, select: Select):
        area = select.values[0]
        user_data = get_user_data(self.user_id)

        area_info = {
            "forest": {"energy": 10, "min_reward": 10, "max_reward": 50, "rare_chance": 5},
            "mountains": {"energy": 20, "min_reward": 25, "max_reward": 100, "rare_chance": 15},
            "desert": {"energy": 30, "min_reward": 50, "max_reward": 200, "rare_chance": 25},
            "volcano": {"energy": 50, "min_reward": 100, "max_reward": 500, "rare_chance": 40}
        }

        info = area_info[area]

        if user_data["exploration_energy"] < info["energy"]:
            await interaction.response.send_message(f"❌ You need {info['energy']} energy but only have {user_data['exploration_energy']}!", ephemeral=True)
            return

        user_data["exploration_energy"] -= info["energy"]
        user_data["stats"]["exploration_count"] += 1

        # Generate rewards
        zolar_reward = random.randint(info["min_reward"], info["max_reward"])
        user_data["zolar"] += zolar_reward

        rewards = [f"💰 {zolar_reward} Zolar"]

        # Rare item chance
        if random.randint(1, 100) <= info["rare_chance"]:
            rare_items = ["Rare Crystal", "Ancient Relic", "Magic Scroll", "Treasure Chest"]
            rare_item = random.choice(rare_items)
            user_data["exploration_rewards"].append(rare_item)
            rewards.append(f"✨ {rare_item}")

        # Random power boost chance
        if random.randint(1, 100) <= 20:
            power_boost = random.randint(5, 25)
            user_data["power"] += power_boost
            rewards.append(f"⚡ +{power_boost} Power")

        save_data(data)

        embed = Embed(
            title=f"🗺️ Exploration Complete - {area.title()}",
            description="You've successfully explored the area!",
            color=discord.Color.green()
        )
        embed.add_field(name="Rewards Found:", value="\n".join(rewards), inline=False)
        embed.add_field(name="Remaining Energy:", value=f"{user_data['exploration_energy']}/100", inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="📋 View Rewards", style=ButtonStyle.blurple)
    async def view_rewards(self, interaction: Interaction, button: Button):
        user_data = get_user_data(self.user_id)

        if not user_data["exploration_rewards"]:
            await interaction.response.send_message("📭 You haven't found any exploration rewards yet!", ephemeral=True)
            return

        embed = Embed(title="🎁 Exploration Rewards", color=discord.Color.blue())
        rewards_text = "\n".join(user_data["exploration_rewards"])
        embed.add_field(name="Items Found:", value=rewards_text, inline=False)
        embed.add_field(name="Total Explorations:", value=user_data["stats"]["exploration_count"], inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    def create_embed(self):
        user_data = get_user_data(self.user_id)
        embed = Embed(title="🗺️ Exploration Hub", description="Choose an area to explore!", color=discord.Color.blue())
        embed.add_field(name="Current Energy:", value=f"{user_data['exploration_energy']}/100", inline=False)
        embed.add_field(name="Areas Available:", value="🌲 Forest (10 Energy)\n🏔️ Mountains (20 Energy)\n🏜️ Desert (30 Energy)\n🌋 Volcano (50 Energy)", inline=False)
        return embed

# -------- FIGHTING SYSTEM --------
class FightView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="🤖 Fight Bot", style=ButtonStyle.red)
    async def fight_bot(self, interaction: Interaction, button: Button):
        user_data = get_user_data(self.user_id)
        user_power = user_data["power"]

        # Generate random bot with power based on user level
        bot_power = random.randint(max(50, user_power - 100), user_power + 100)
        bot_name = random.choice(["Iron Golem", "Shadow Warrior", "Fire Elemental", "Ice Beast", "Thunder Lord"])

        # Battle calculation
        win_chance = min(90, max(10, 50 + (user_power - bot_power) / 10))
        won = random.randint(1, 100) <= win_chance

        if won:
            zolar_reward = random.randint(50, 200)
            xp_reward = random.randint(20, 50)
            user_data["zolar"] += zolar_reward
            await add_xp(self.user_id, xp_reward)
            user_data["stats"]["wins"] += 1

            embed = Embed(title="🎉 Victory!", description=f"You defeated {bot_name}!", color=discord.Color.green())
            embed.add_field(name="Rewards:", value=f"💰 {zolar_reward} Zolar\n✨ {xp_reward} XP", inline=False)
        else:
            zolar_lost = random.randint(10, 50)
            user_data["zolar"] = max(0, user_data["zolar"] - zolar_lost)
            user_data["stats"]["losses"] += 1

            embed = Embed(title="💀 Defeat!", description=f"{bot_name} defeated you!", color=discord.Color.red())
            embed.add_field(name="Lost:", value=f"💰 {zolar_lost} Zolar", inline=False)

        embed.add_field(name="Battle Stats:", value=f"Your Power: {user_power}\nEnemy Power: {bot_power}", inline=False)
        save_data(data)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="⚔️ Challenge Player", style=ButtonStyle.blurple)
    async def challenge_player(self, interaction: Interaction, button: Button):
        embed = Embed(title="⚔️ Player Challenges", description="Use `/duel @player` to challenge another player!", color=discord.Color.blue())
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="📊 Battle Stats", style=ButtonStyle.gray)
    async def battle_stats(self, interaction: Interaction, button: Button):
        user_data = get_user_data(self.user_id)
        stats = user_data["stats"]

        embed = Embed(title="📊 Battle Statistics", color=discord.Color.blue())
        embed.add_field(name="Wins:", value=stats["wins"], inline=True)
        embed.add_field(name="Losses:", value=stats["losses"], inline=True)
        total_battles = stats['wins'] + stats['losses']
        win_rate = f"{(stats['wins']/total_battles)*100:.1f}%" if total_battles > 0 else "0%"
        embed.add_field(name="Win Rate:", value=win_rate, inline=True)
        embed.add_field(name="Current Power:", value=user_data["power"], inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    def create_embed(self):
        user_data = get_user_data(self.user_id)
        embed = Embed(title="⚔️ Battle Arena", description="Test your strength in combat!", color=discord.Color.red())
        embed.add_field(name="Your Power:", value=user_data["power"], inline=True)
        embed.add_field(name="Battle Record:", value=f"W: {user_data['stats']['wins']} | L: {user_data['stats']['losses']}", inline=True)
        return embed

# -------- GAMES SYSTEM --------
class GamesView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="🃏 Blackjack", style=ButtonStyle.green)
    async def play_blackjack(self, interaction: Interaction, button: Button):
        modal = BetModal("blackjack")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🎰 Poker", style=ButtonStyle.red)
    async def play_poker(self, interaction: Interaction, button: Button):
        modal = BetModal("poker")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🎲 Dice Game", style=ButtonStyle.blurple)
    async def play_dice(self, interaction: Interaction, button: Button):
        modal = BetModal("dice")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🎯 Number Guess", style=ButtonStyle.gray)
    async def play_guess(self, interaction: Interaction, button: Button):
        modal = BetModal("guess")
        await interaction.response.send_modal(modal)

    def create_embed(self):
        user_data = get_user_data(self.user_id)
        embed = Embed(title="🎮 Games Hub", description="Choose a game to play!", color=discord.Color.purple())
        embed.add_field(name="Your Balance:", value=f"{user_data['zolar']} Zolar", inline=False)
        embed.add_field(name="Available Games:", value="🃏 Blackjack\n🎰 Poker\n🎲 Dice Game\n🎯 Number Guess", inline=False)
        return embed

class BetModal(Modal):
    def __init__(self, game_type):
        super().__init__(title=f"💰 Place Your Bet - {game_type.title()}")
        self.game_type = game_type

        self.bet_input = TextInput(
            label="Bet Amount (Zolar)",
            placeholder="Enter your bet amount...",
            required=True,
            max_length=10
        )
        self.add_item(self.bet_input)

    async def on_submit(self, interaction: Interaction):
        try:
            bet = int(self.bet_input.value)
        except ValueError:
            await interaction.response.send_message("❌ Please enter a valid number!", ephemeral=True)
            return

        user_data = get_user_data(interaction.user.id)

        if bet <= 0:
            await interaction.response.send_message("❌ Bet must be positive!", ephemeral=True)
            return

        if user_data["zolar"] < bet:
            await interaction.response.send_message("❌ You don't have enough Zolar!", ephemeral=True)
            return

        if self.game_type == "blackjack":
            await self.play_blackjack(interaction, bet)
        elif self.game_type == "poker":
            await self.play_poker(interaction, bet)
        elif self.game_type == "dice":
            await self.play_dice(interaction, bet)
        elif self.game_type == "guess":
            await self.play_guess(interaction, bet)

    async def play_blackjack(self, interaction, bet):
        # Simplified blackjack
        user_data = get_user_data(interaction.user.id)
        user_data["zolar"] -= bet

        player_cards = random.randint(16, 21)
        dealer_cards = random.randint(16, 21)

        if player_cards > dealer_cards and player_cards <= 21:
            winnings = bet * 2
            user_data["zolar"] += winnings
            result = f"🎉 You won! Cards: {player_cards} vs {dealer_cards}\nWon: {winnings} Zolar"
            color = discord.Color.green()
        elif player_cards == dealer_cards:
            user_data["zolar"] += bet
            result = f"🤝 Tie! Cards: {player_cards} vs {dealer_cards}\nBet returned"
            color = discord.Color.yellow()
        else:
            result = f"💀 You lost! Cards: {player_cards} vs {dealer_cards}\nLost: {bet} Zolar"
            color = discord.Color.red()

        save_data(data)
        embed = Embed(title="🃏 Blackjack Result", description=result, color=color)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    async def play_poker(self, interaction, bet):
        user_data = get_user_data(interaction.user.id)
        user_data["zolar"] -= bet

        hands = ["High Card", "Pair", "Two Pair", "Three of a Kind", "Straight", "Flush", "Full House", "Four of a Kind", "Royal Flush"]
        player_hand = random.choice(hands)
        dealer_hand = random.choice(hands)

        player_rank = hands.index(player_hand)
        dealer_rank = hands.index(dealer_hand)

        if player_rank > dealer_rank:
            winnings = bet * (2 + player_rank // 3)
            user_data["zolar"] += winnings
            result = f"🎉 You won! {player_hand} beats {dealer_hand}\nWon: {winnings} Zolar"
            color = discord.Color.green()
        elif player_rank == dealer_rank:
            user_data["zolar"] += bet
            result = f"🤝 Tie! Both had {player_hand}\nBet returned"
            color = discord.Color.yellow()
        else:
            result = f"💀 You lost! {dealer_hand} beats {player_hand}\nLost: {bet} Zolar"
            color = discord.Color.red()

        save_data(data)
        embed = Embed(title="🎰 Poker Result", description=result, color=color)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    async def play_dice(self, interaction, bet):
        user_data = get_user_data(interaction.user.id)
        user_data["zolar"] -= bet

        player_dice = [random.randint(1, 6) for _ in range(2)]
        dealer_dice = [random.randint(1, 6) for _ in range(2)]

        player_total = sum(player_dice)
        dealer_total = sum(dealer_dice)

        if player_total > dealer_total:
            winnings = bet * 2
            user_data["zolar"] += winnings
            result = f"🎉 You won! {player_dice} ({player_total}) vs {dealer_dice} ({dealer_total})\nWon: {winnings} Zolar"
            color = discord.Color.green()
        elif player_total == dealer_total:
            user_data["zolar"] += bet
            result = f"🤝 Tie! {player_dice} ({player_total}) vs {dealer_dice} ({dealer_total})\nBet returned"
            color = discord.Color.yellow()
        else:
            result = f"💀 You lost! {player_dice} ({player_total}) vs {dealer_dice} ({dealer_total})\nLost: {bet} Zolar"
            color = discord.Color.red()

        save_data(data)
        embed = Embed(title="🎲 Dice Game Result", description=result, color=color)
        await interaction.response.send_message(embed=embed, ephemeral=True)

    async def play_guess(self, interaction, bet):
        user_data = get_user_data(interaction.user.id)
        user_data["zolar"] -= bet

        target = random.randint(1, 10)
        guess = random.randint(1, 10)

        if guess == target:
            winnings = bet * 5
            user_data["zolar"] += winnings
            result = f"🎯 Perfect guess! Number was {target}\nWon: {winnings} Zolar"
            color = discord.Color.green()
        elif abs(guess - target) <= 1:
            winnings = bet * 2
            user_data["zolar"] += winnings
            result = f"🎯 Close! Guessed {guess}, number was {target}\nWon: {winnings} Zolar"
            color = discord.Color.green()
        else:
            result = f"❌ Wrong! Guessed {guess}, number was {target}\nLost: {bet} Zolar"
            color = discord.Color.red()

        save_data(data)
        embed = Embed(title="🎯 Number Guess Result", description=result, color=color)
        await interaction.response.send_message(embed=embed, ephemeral=True)

# -------- MAIN COMMANDS --------
@tree.command(name="shop", description="🏪 Open the Empire Shop")
async def shop(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    view = ShopView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view)

@tree.command(name="explore", description="🗺️ Explore different areas for rewards")
async def explore(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    view = ExplorationView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view)

@tree.command(name="fight", description="⚔️ Enter the battle arena")
async def fight(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    view = FightView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view)

@tree.command(name="games", description="🎮 Play various gambling games")
async def games(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    view = GamesView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view)

@tree.command(name="profile", description="👤 View your profile and stats")
async def profile(interaction: Interaction, member: discord.Member = None):
    member = member or interaction.user

    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    user_data = get_user_data(member.id)

    embed = Embed(title=f"👤 {member.display_name}'s Profile", color=discord.Color.blue())
    embed.set_thumbnail(url=member.avatar.url if member.avatar else discord.Embed.Empty)

    # Basic info
    embed.add_field(name="Level", value=user_data["level"], inline=True)
    embed.add_field(name="Rank", value=user_data["rank"], inline=True)
    embed.add_field(name="Power", value=user_data["power"], inline=True)
    embed.add_field(name="Zolar", value=user_data["zolar"], inline=True)
    embed.add_field(name="XP", value=f"{user_data['xp']}/{100 * user_data['level']}", inline=True)
    embed.add_field(name="Energy", value=f"{user_data['exploration_energy']}/100", inline=True)

    # Equipment
    equipment = user_data["equipment"]
    eq_text = f"Weapon: {equipment['weapon'] or 'None'}\nArmor: {equipment['armor'] or 'None'}\nAccessory: {equipment['accessory'] or 'None'}"
    embed.add_field(name="Equipment", value=eq_text, inline=False)

    # Stats
    stats = user_data.get("stats", {"wins": 0, "losses": 0, "exploration_count": 0})
    stats_text = f"Wins: {stats.get('wins', 0)}\nLosses: {stats.get('losses', 0)}\nExplorations: {stats.get('exploration_count', 0)}"
    embed.add_field(name="Statistics", value=stats_text, inline=False)

    await interaction.response.send_message(embed=embed)

@tree.command(name="redeem", description="🎁 Redeem exploration rewards")
async def redeem(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    user_data = get_user_data(interaction.user.id)

    if not user_data["exploration_rewards"]:
        await interaction.response.send_message("📭 You have no rewards to redeem!", ephemeral=True)
        return

    total_zolar = 0
    total_power = 0
    redeemed_items = []

    for reward in user_data["exploration_rewards"]:
        if "Crystal" in reward:
            zolar_value = random.randint(50, 150)
            total_zolar += zolar_value
        elif "Relic" in reward:
            power_value = random.randint(20, 50)
            total_power += power_value
        elif "Scroll" in reward:
            zolar_value = random.randint(100, 300)
            total_zolar += zolar_value
        elif "Chest" in reward:
            zolar_value = random.randint(200, 500)
            power_value = random.randint(50, 100)
            total_zolar += zolar_value
            total_power += power_value

        redeemed_items.append(reward)

    user_data["zolar"] += total_zolar
    user_data["power"] += total_power
    user_data["exploration_rewards"] = []
    save_data(data)

    embed = Embed(title="🎁 Rewards Redeemed!", color=discord.Color.green())
    embed.add_field(name="Items Redeemed:", value="\n".join(redeemed_items), inline=False)

    if total_zolar > 0:
        embed.add_field(name="Zolar Gained:", value=f"+{total_zolar}", inline=True)
    if total_power > 0:
        embed.add_field(name="Power Gained:", value=f"+{total_power}", inline=True)

    await interaction.response.send_message(embed=embed)

@tree.command(name="balance", description="💰 Check your current balance")
async def balance(interaction: Interaction, member: discord.Member = None):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    member = member or interaction.user
    user_data = get_user_data(member.id)

    embed = Embed(title=f"💰 {member.display_name}'s Balance", color=discord.Color.gold())
    embed.set_thumbnail(url=member.avatar.url if member.avatar else discord.Embed.Empty)
    embed.add_field(name="Zolar", value=f"{user_data['zolar']:,}", inline=True)
    embed.add_field(name="Level", value=user_data["level"], inline=True)
    embed.add_field(name="Power", value=f"{user_data['power']:,}", inline=True)
    embed.add_field(name="Energy", value=f"{user_data['exploration_energy']}/100", inline=True)
    embed.add_field(name="Rank", value=user_data["rank"], inline=True)
    embed.add_field(name="XP", value=f"{user_data['xp']}/{100 * user_data['level']}", inline=True)

    await interaction.response.send_message(embed=embed)

@tree.command(name="power", description="⚡ Check your current power level")
async def power(interaction: Interaction, member: discord.Member = None):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    member = member or interaction.user
    user_data = get_user_data(member.id)

    embed = Embed(title=f"⚡ {member.display_name}'s Power", color=discord.Color.orange())
    embed.set_thumbnail(url=member.avatar.url if member.avatar else discord.Embed.Empty)
    embed.add_field(name="Current Power", value=f"{user_data['power']:,}", inline=True)
    embed.add_field(name="Rank", value=user_data["rank"], inline=True)
    embed.add_field(name="Level", value=user_data["level"], inline=True)

    # Show equipment bonuses
    equipment = user_data["equipment"]
    equipment_text = []
    if equipment["weapon"]:
        equipment_text.append(f"🗡️ {equipment['weapon']}")
    if equipment["armor"]:
        equipment_text.append(f"🛡️ {equipment['armor']}")
    if equipment["accessory"]:
        equipment_text.append(f"💎 {equipment['accessory']}")

    if equipment_text:
        embed.add_field(name="Equipment Equipped", value="\n".join(equipment_text), inline=False)
    else:
        embed.add_field(name="Equipment Equipped", value="None", inline=False)

    await interaction.response.send_message(embed=embed)

# -------- REMOVE OLD COMMANDS AND SYNC --------
async def cleanup_old_commands():
    """Remove old admin commands"""
    try:
        # Clear all commands globally
        tree.clear_commands(guild=None)

        # Clear commands from all guilds
        for guild in bot.guilds:
            try:
                tree.clear_commands(guild=guild)
            except Exception as e:
                print(f"❌ Error clearing commands for guild {guild.name}: {e}")

        print("✅ Old commands cleaned up")
    except Exception as e:
        print(f"❌ Error cleaning commands: {e}")

# -------- UNIFIED ADMIN SYSTEM --------
class AdminView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Choose an admin function...",
        options=[
            SelectOption(label="💰 Give Currency/Stats", description="Give zolar, power, XP, levels", emoji="💰", value="give_currency"),
            SelectOption(label="🎁 Give Items", description="Give weapons, armor, accessories", emoji="🎁", value="give_items"),
            SelectOption(label="👤 User Management", description="Ban, unban, reset users", emoji="👤", value="user_mgmt"),
            SelectOption(label="📊 Bot Statistics", description="View server and bot stats", emoji="📊", value="stats"),
            SelectOption(label="⚠️ Dangerous Actions", description="Data wipe and other critical actions", emoji="⚠️", value="dangerous")
        ]
    )
    async def admin_category(self, interaction: Interaction, select: Select):
        category = select.values[0]

        if category == "give_currency":
            view = GiveCurrencyView(self.user_id)
        elif category == "give_items":
            view = GiveItemsView(self.user_id)
        elif category == "user_mgmt":
            view = UserManagementView(self.user_id)
        elif category == "stats":
            view = AdminStatsView(self.user_id)
        elif category == "dangerous":
            view = DangerousActionsView(self.user_id)

        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="🔧 Admin Panel", description="Select a category to manage the bot:", color=discord.Color.red())
        embed.add_field(name="Available Functions:", value="💰 Give Currency/Stats\n🎁 Give Items\n👤 User Management\n📊 Bot Statistics\n⚠️ Dangerous Actions", inline=False)
        embed.set_footer(text="Admin access required")
        return embed

class GiveCurrencyView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="💰 Give Zolar", style=ButtonStyle.green)
    async def give_zolar(self, interaction: Interaction, button: Button):
        modal = GiveCurrencyModal("zolar")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="⚡ Give Power", style=ButtonStyle.blurple)
    async def give_power(self, interaction: Interaction, button: Button):
        modal = GiveCurrencyModal("power")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="✨ Give XP", style=ButtonStyle.gray)
    async def give_xp(self, interaction: Interaction, button: Button):
        modal = GiveCurrencyModal("xp")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="📈 Give Levels", style=ButtonStyle.red)
    async def give_levels(self, interaction: Interaction, button: Button):
        modal = GiveCurrencyModal("level")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔋 Give Energy", style=ButtonStyle.green)
    async def give_energy(self, interaction: Interaction, button: Button):
        modal = GiveCurrencyModal("energy")
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔙 Back to Admin Panel", style=ButtonStyle.gray)
    async def back_to_admin(self, interaction: Interaction, button: Button):
        view = AdminView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="💰 Give Currency & Stats", description="Give various currencies and stats to users", color=discord.Color.green())
        embed.add_field(name="Available Options:", value="💰 Zolar - Main currency\n⚡ Power - Combat power\n✨ XP - Experience points\n📈 Levels - User level\n🔋 Energy - Exploration energy", inline=False)
        return embed

class GiveItemsView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.select(
        placeholder="Select item category...",
        options=[
            SelectOption(label="⚔️ Weapons", description="Swords and combat weapons", emoji="⚔️", value="weapons"),
            SelectOption(label="🛡️ Armor", description="Protective gear", emoji="🛡️", value="armor"),
            SelectOption(label="💎 Premium Items", description="Legendary equipment", emoji="💎", value="premium"),
            SelectOption(label="🧪 Consumables", description="Potions and consumables", emoji="🧪", value="consumables")
        ]
    )
    async def item_category(self, interaction: Interaction, select: Select):
        category = select.values[0]
        modal = GiveItemModal(category)
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔙 Back to Admin Panel", style=ButtonStyle.gray)
    async def back_to_admin(self, interaction: Interaction, button: Button):
        view = AdminView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="🎁 Give Items", description="Give items to users", color=discord.Color.blue())
        embed.add_field(name="Item Categories:", value="⚔️ Weapons - Combat weapons\n🛡️ Armor - Protective gear\n💎 Premium Items - Legendary equipment\n🧪 Consumables - Potions and items", inline=False)
        return embed

class UserManagementView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="🔨 Ban User", style=ButtonStyle.red)
    async def ban_user(self, interaction: Interaction, button: Button):
        modal = BanUserModal()
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="✅ Unban User", style=ButtonStyle.green)
    async def unban_user(self, interaction: Interaction, button: Button):
        modal = UnbanUserModal()
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔄 Reset User Data", style=ButtonStyle.blurple)
    async def reset_user(self, interaction: Interaction, button: Button):
        modal = ResetUserModal()
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="📋 View User Data", style=ButtonStyle.gray)
    async def view_user(self, interaction: Interaction, button: Button):
        modal = ViewUserModal()
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔙 Back to Admin Panel", style=ButtonStyle.gray)
    async def back_to_admin(self, interaction: Interaction, button: Button):
        view = AdminView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="👤 User Management", description="Manage users and their data", color=discord.Color.orange())
        embed.add_field(name="Available Actions:", value="🔨 Ban User - Ban users from bot\n✅ Unban User - Remove bans\n🔄 Reset User Data - Clear user progress\n📋 View User Data - Inspect user info", inline=False)
        return embed

class AdminStatsView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="📊 View Statistics", style=ButtonStyle.blurple)
    async def view_stats(self, interaction: Interaction, button: Button):
        total_users = len(data)
        total_zolar = sum(user.get("zolar", 0) for user in data.values())
        total_power = sum(user.get("power", 0) for user in data.values())
        banned_users = sum(1 for user in data.values() if user.get("banned", False))

        # Calculate rank distribution
        rank_count = {}
        for user in data.values():
            rank = user.get("rank", "Peasant")
            rank_count[rank] = rank_count.get(rank, 0) + 1

        embed = Embed(title="📊 Bot Statistics", color=discord.Color.blue())
        embed.add_field(name="Users", value=f"Total: {total_users}\nBanned: {banned_users}", inline=True)
        embed.add_field(name="Economy", value=f"Total Zolar: {total_zolar:,}\nTotal Power: {total_power:,}", inline=True)
        embed.add_field(name="Active Users", value=f"{total_users - banned_users}", inline=True)

        if rank_count:
            rank_text = "\n".join([f"{rank}: {count}" for rank, count in rank_count.items()])
            embed.add_field(name="Rank Distribution", value=rank_text, inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Admin Panel", style=ButtonStyle.gray)
    async def back_to_admin(self, interaction: Interaction, button: Button):
        view = AdminView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="📊 Bot Statistics", description="View comprehensive bot statistics", color=discord.Color.blue())
        embed.add_field(name="Available Data:", value="👥 User counts and activity\n💰 Economic statistics\n📈 Rank distributions\n🚫 Ban information", inline=False)
        return embed

class DangerousActionsView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="💥 Wipe All Data", style=ButtonStyle.red)
    async def wipe_data(self, interaction: Interaction, button: Button):
        modal = WipeDataModal()
        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🔙 Back to Admin Panel", style=ButtonStyle.gray)
    async def back_to_admin(self, interaction: Interaction, button: Button):
        view = AdminView(self.user_id)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="⚠️ Dangerous Actions", description="**WARNING: These actions are irreversible!**", color=discord.Color.red())
        embed.add_field(name="Available Actions:", value="💥 Wipe All Data - Delete all user data", inline=False)
        embed.add_field(name="⚠️ Warning:", value="These actions cannot be undone. Use with extreme caution!", inline=False)
        return embed

# Modal classes for admin functions
class GiveCurrencyModal(Modal):
    def __init__(self, currency_type):
        super().__init__(title=f"Give {currency_type.title()}")
        self.currency_type = currency_type

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

        self.amount_input = TextInput(
            label=f"Amount of {currency_type.title()}",
            placeholder=f"Enter amount of {currency_type}...",
            required=True,
            max_length=10
        )
        self.add_item(self.amount_input)

    async def on_submit(self, interaction: Interaction):
        try:
            amount = int(self.amount_input.value)
        except ValueError:
            await interaction.response.send_message("❌ Please enter a valid number!", ephemeral=True)
            return

        user_input = self.user_input.value.strip()
        member = None

        # Try to get member by mention or ID
        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        user_data = get_user_data(member.id)

        if self.currency_type == "zolar":
            user_data["zolar"] += amount
        elif self.currency_type == "power":
            user_data["power"] += amount
        elif self.currency_type == "energy":
            user_data["exploration_energy"] = min(100, user_data["exploration_energy"] + amount)
        elif self.currency_type == "xp":
            await add_xp(member.id, amount)
        elif self.currency_type == "level":
            user_data["level"] += amount
            rank_info = get_rank_by_level(user_data["level"])
            user_data["rank"] = rank_info["name"]

        save_data(data)

        embed = Embed(
            title="✅ Successfully Given!",
            description=f"Gave **{amount} {self.currency_type.title()}** to {member.mention}",
            color=discord.Color.green()
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)

class GiveItemModal(Modal):
    def __init__(self, category):
        super().__init__(title=f"Give {category.title()}")
        self.category = category

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

        self.item_input = TextInput(
            label="Item Name",
            placeholder="Enter item name...",
            required=True,
            max_length=50
        )
        self.add_item(self.item_input)

    async def on_submit(self, interaction: Interaction):
        user_input = self.user_input.value.strip()
        item_name = self.item_input.value.strip()
        member = None

        # Try to get member by mention or ID
        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        user_data = get_user_data(member.id)

        # Item database
        items_db = {
            "iron sword": {"power": 50, "type": "weapon"},
            "steel sword": {"power": 100, "type": "weapon"},
            "dragon blade": {"power": 300, "type": "weapon"},
            "legendary sword": {"power": 500, "type": "weapon"},
            "leather armor": {"power": 30, "type": "armor"},
            "chain mail": {"power": 80, "type": "armor"},
            "dragon scale": {"power": 250, "type": "armor"},
            "divine armor": {"power": 400, "type": "armor"},
            "crown of kings": {"power": 1000, "type": "accessory"},
            "dragon pet": {"power": 200, "type": "pet"}
        }

        item_key = item_name.lower()
        if item_key not in items_db:
            await interaction.response.send_message(f"❌ Item '{item_name}' not found!", ephemeral=True)
            return

        item = items_db[item_key]
        formatted_name = item_name.title()

        user_data["inventory"].append(formatted_name)
        user_data["power"] += item["power"]

        if item["type"] in ["weapon", "armor", "accessory"]:
            user_data["equipment"][item["type"]] = formatted_name

        save_data(data)

        embed = Embed(
            title="✅ Item Given Successfully!",
            description=f"Gave **{formatted_name}** to {member.mention}",
            color=discord.Color.green()
        )
        embed.add_field(name="Power Bonus", value=f"+{item['power']}", inline=True)
        embed.add_field(name="Type", value=item["type"].title(), inline=True)

        await interaction.response.send_message(embed=embed, ephemeral=True)

class BanUserModal(Modal):
    def __init__(self):
        super().__init__(title="Ban User")

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

        self.reason_input = TextInput(
            label="Ban Reason",
            placeholder="Enter reason for ban...",
            required=False,
            max_length=200
        )
        self.add_item(self.reason_input)

    async def on_submit(self, interaction: Interaction):
        user_input = self.user_input.value.strip()
        reason = self.reason_input.value or "No reason provided"
        member = None

        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        user_data = get_user_data(member.id)
        user_data["banned"] = True
        user_data["ban_reason"] = reason
        save_data(data)

        embed = Embed(
            title="🔨 User Banned",
            description=f"Banned {member.mention}",
            color=discord.Color.red()
        )
        embed.add_field(name="Reason", value=reason, inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

class UnbanUserModal(Modal):
    def __init__(self):
        super().__init__(title="Unban User")

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

    async def on_submit(self, interaction: Interaction):
        user_input = self.user_input.value.strip()
        member = None

        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        user_data = get_user_data(member.id)
        user_data["banned"] = False
        if "ban_reason" in user_data:
            del user_data["ban_reason"]
        save_data(data)

        await interaction.response.send_message(f"✅ Unbanned {member.mention}", ephemeral=True)

class ResetUserModal(Modal):
    def __init__(self):
        super().__init__(title="Reset User Data")

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

    async def on_submit(self, interaction: Interaction):
        user_input = self.user_input.value.strip()
        member = None

        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        uid = str(member.id)
        if uid in data:
            del data[uid]
            save_data(data)

        await interaction.response.send_message(f"✅ Reset {member.mention}'s data.", ephemeral=True)

class ViewUserModal(Modal):
    def __init__(self):
        super().__init__(title="View User Data")

        self.user_input = TextInput(
            label="User ID or Mention",
            placeholder="Enter user ID or @mention...",
            required=True,
            max_length=50
        )
        self.add_item(self.user_input)

    async def on_submit(self, interaction: Interaction):
        user_input = self.user_input.value.strip()
        member = None

        if user_input.startswith('<@') and user_input.endswith('>'):
            user_id = int(user_input[2:-1].replace('!', ''))
            member = interaction.guild.get_member(user_id)
        else:
            try:
                user_id = int(user_input)
                member = interaction.guild.get_member(user_id)
            except ValueError:
                await interaction.response.send_message("❌ Invalid user ID or mention!", ephemeral=True)
                return

        if not member:
            await interaction.response.send_message("❌ User not found in this server!", ephemeral=True)
            return

        user_data = get_user_data(member.id)

        embed = Embed(title=f"📋 {member.display_name}'s Data", color=discord.Color.blue())
        embed.set_thumbnail(url=member.avatar.url if member.avatar else discord.Embed.Empty)

        embed.add_field(name="Basic Info", value=f"Level: {user_data['level']}\nRank: {user_data['rank']}\nXP: {user_data['xp']}", inline=True)
        embed.add_field(name="Resources", value=f"Zolar: {user_data['zolar']}\nPower: {user_data['power']}\nEnergy: {user_data['exploration_energy']}", inline=True)
        embed.add_field(name="Status", value=f"Banned: {user_data.get('banned', False)}", inline=True)

        stats = user_data.get("stats", {"wins": 0, "losses": 0, "exploration_count": 0})
        embed.add_field(name="Statistics", value=f"Wins: {stats.get('wins', 0)}\nLosses: {stats.get('losses', 0)}\nExplorations: {stats.get('exploration_count', 0)}", inline=False)

        await interaction.response.send_message(embed=embed, ephemeral=True)

class WipeDataModal(Modal):
    def __init__(self):
        super().__init__(title="⚠️ WIPE ALL DATA")

        self.confirm_input = TextInput(
            label="Type 'CONFIRM WIPE' to proceed",
            placeholder="This action cannot be undone!",
            required=True,
            max_length=20
        )
        self.add_item(self.confirm_input)

    async def on_submit(self, interaction: Interaction):
        if self.confirm_input.value != "CONFIRM WIPE":
            await interaction.response.send_message("❌ Confirmation text incorrect. Data wipe cancelled.", ephemeral=True)
            return

        global data
        data = {}
        save_data(data)

        await interaction.response.send_message("💥 **ALL USER DATA WIPED!**", ephemeral=True)

@tree.command(name="admin", description="🔧 Open the unified admin panel")
async def admin(interaction: Interaction):
    if not is_admin(interaction.user.id):
        await interaction.response.send_message("❌ Admin only command!", ephemeral=True)
        return

    view = AdminView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view, ephemeral=True)

@tree.command(name="setup", description="🔧 Set up Empire Bot for your server")
async def setup(interaction: Interaction):
    if not interaction.user.guild_permissions.administrator:
        await interaction.response.send_message("❌ You need Administrator permissions to use this command!", ephemeral=True)
        return

    # Defer the response immediately to prevent timeout
    await interaction.response.defer()

    guild = interaction.guild

    try:
        # Create Empire Bot category
        category = discord.utils.get(guild.categories, name="🏰 Empire Bot")
        if not category:
            category = await guild.create_category("🏰 Empire Bot")

        # Create channels
        channels_to_create = [
            ("🏪-shop", "Browse and purchase items from the Empire Shop"),
            ("⚔️-battle-arena", "Challenge others and fight monsters"),
            ("🗺️-exploration", "Explore different areas for rewards"),
            ("🎮-games", "Play various gambling games"),
            ("📊-leaderboard", "View top players and rankings"),
            ("💰-auctions", "Buy and sell rare items"),
            ("📢-announcements", "Bot updates and news")
        ]

        created_channels = []
        for channel_name, topic in channels_to_create:
            existing_channel = discord.utils.get(guild.text_channels, name=channel_name)
            if not existing_channel:
                channel = await guild.create_text_channel(
                    channel_name,
                    category=category,
                    topic=topic
                )
                created_channels.append(channel.name)

        # Create Empire Bot role
        empire_role = discord.utils.get(guild.roles, name="Empire Player")
        if not empire_role:
            empire_role = await guild.create_role(
                name="Empire Player",
                color=discord.Color.blue(),
                reason="Empire Bot Setup"
            )

        # Create VIP role
        vip_role = discord.utils.get(guild.roles, name="Empire VIP")
        if not vip_role:
            vip_role = await guild.create_role(
                name="Empire VIP",
                color=discord.Color.gold(),
                reason="Empire Bot Setup"
            )

        # Create rank roles
        rank_roles = ["Knight", "Baron", "Duke", "Prince", "King"]
        colors = [discord.Color.green(), discord.Color.blue(), discord.Color.purple(), discord.Color.orange(), discord.Color.red()]

        created_roles = []
        for i, rank in enumerate(rank_roles):
            existing_role = discord.utils.get(guild.roles, name=f"Empire {rank}")
            if not existing_role:
                role = await guild.create_role(
                    name=f"Empire {rank}",
                    color=colors[i],
                    reason="Empire Bot Setup - Rank Role"
                )
                created_roles.append(role.name)

        # Setup embed
        embed = Embed(
            title="🎉 Empire Bot Setup Complete!",
            description="Your server has been configured for Empire Bot!",
            color=discord.Color.green()
        )

        if created_channels:
            embed.add_field(
                name="📝 Channels Created:",
                value="\n".join([f"#{channel}" for channel in created_channels]),
                inline=False
            )

        if created_roles:
            embed.add_field(
                name="👑 Roles Created:",
                value="\n".join(created_roles),
                inline=False
            )

        embed.add_field(
            name="🚀 Getting Started:",
            value="• Use `/help` to see all commands\n• Use `/profile` to view your stats\n• Use `/shop` to browse items\n• Use `/explore` to start your adventure!",
            inline=False
        )

        embed.add_field(
            name="⚙️ Features Setup:",
            value="✅ Categories & Channels\n✅ Player Roles\n✅ Rank System\n✅ Ready to use!",
            inline=False
        )

        await interaction.followup.send(embed=embed)

    except discord.Forbidden:
        try:
            await interaction.followup.send("❌ I don't have permissions to create channels/roles! Please check my permissions.")
        except:
            print("Failed to send error message - interaction already expired")
    except Exception as e:
        try:
            await interaction.followup.send(f"❌ Setup failed: {str(e)}")
        except:
            print(f"Failed to send error message - interaction already expired. Error was: {e}")

@tree.command(name="sync", description="🔄 Sync bot commands (Admin only)")
async def sync_commands(interaction: Interaction):
    if not is_admin(interaction.user.id):
        await interaction.response.send_message("❌ Admin only command!", ephemeral=True)
        return

    try:
        await interaction.response.defer(ephemeral=True)

        # Only clear if explicitly needed, then sync
        tree.clear_commands(guild=None)

        # Sync globally
        global_synced = await tree.sync()

        # Sync to current guild
        guild_synced = await tree.sync(guild=interaction.guild)

        embed = Embed(
            title="✅ Commands Synced Successfully!",
            description=f"Global: {len(global_synced)} commands\nGuild: {len(guild_synced)} commands",
            color=discord.Color.green()
        )
        embed.add_field(
            name="📱 Mobile Users",
            value="If commands don't appear on mobile:\n• Restart Discord app\n• Wait 1-2 minutes\n• Check bot permissions",
            inline=False
        )

        await interaction.followup.send(embed=embed, ephemeral=True)

    except Exception as e:
        await interaction.followup.send(f"❌ Error syncing commands: {str(e)}", ephemeral=True)

@tree.command(name="botinfo", description="🤖 Check bot status and permissions")
async def botinfo(interaction: Interaction):
    bot_member = interaction.guild.get_member(bot.user.id)
    permissions = bot_member.guild_permissions

    embed = Embed(title="🤖 Bot Information", color=discord.Color.blue())
    embed.add_field(name="Bot Status", value="✅ Online", inline=True)
    embed.add_field(name="Latency", value=f"{round(bot.latency * 1000)}ms", inline=True)
    embed.add_field(name="Servers", value=len(bot.guilds), inline=True)

    # Check important permissions
    important_perms = {
        "Send Messages": permissions.send_messages,
        "Use Application Commands": permissions.use_application_commands,
        "Embed Links": permissions.embed_links,
        "Add Reactions": permissions.add_reactions,
        "Read Message History": permissions.read_message_history
    }

    perm_status = []
    for perm, has_perm in important_perms.items():
        status = "✅" if has_perm else "❌"
        perm_status.append(f"{status} {perm}")

    embed.add_field(name="Key Permissions", value="\n".join(perm_status), inline=False)

    if not all(important_perms.values()):
        embed.add_field(
            name="⚠️ Missing Permissions",
            value="Some commands may not work properly. Contact an admin to fix bot permissions.",
            inline=False
        )

    embed.add_field(
        name="📱 Mobile Issues?",
        value="If commands don't show on mobile:\n• Use `/sync` command\n• Restart Discord app\n• Wait 1-2 minutes",
        inline=False
    )

    await interaction.response.send_message(embed=embed)

@tree.command(name="help", description="📜 View all available commands")
async def help_cmd(interaction: Interaction):
    user_data = get_user_data(interaction.user.id)

    embed = Embed(title="📜 Empire Bot Commands", color=discord.Color.blue())
    embed.add_field(name="🏪 /shop", value="Open the comprehensive shop", inline=False)
    embed.add_field(name="🗺️ /explore", value="Explore areas for rewards", inline=False)
    embed.add_field(name="⚔️ /fight", value="Battle in the arena", inline=False)
    embed.add_field(name="🎮 /games", value="Play various gambling games", inline=False)
    embed.add_field(name="👤 /profile", value="View user profile", inline=False)
    embed.add_field(name="💰 /balance", value="Check your balance", inline=False)
    embed.add_field(name="⚡ /power", value="Check your power level", inline=False)
    embed.add_field(name="🎁 /redeem", value="Redeem exploration rewards", inline=False)
    embed.add_field(name="🏛️ /auction", value="Access the auction house", inline=False)
    embed.add_field(name="⚔️ /duel", value="Challenge another player", inline=False)
    embed.add_field(name="🔧 /setup", value="Setup bot for your server (Admin only)", inline=False)

    if is_admin(interaction.user.id):
        embed.add_field(
            name="🔧 Admin Commands",
            value="/admin - Unified admin panel with all functions\n/sync - Sync and clean commands",
            inline=False
        )

    embed.set_footer(text="Empire Bot - Latest Version with Unified Admin System")
    await interaction.response.send_message(embed=embed)

# -------- AUCTION SYSTEM --------
class AuctionView(View):
    def __init__(self, user_id):
        super().__init__(timeout=300)
        self.user_id = user_id

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="📦 List Item", style=ButtonStyle.green)
    async def list_item(self, interaction: Interaction, button: Button):
        modal = ListItemModal()
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="🔍 Browse Auctions", style=ButtonStyle.blurple)
    async def browse_auctions(self, interaction: Interaction, button: Button):
        # For now, show placeholder message
        embed = Embed(
            title="🔍 Auction House",
            description="Coming soon! Advanced auction system will be available in future updates.",
            color=discord.Color.blue()
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)

    def create_embed(self):
        embed = Embed(title="🏛️ Auction House", description="Buy and sell rare items!", color=discord.Color.purple())
        embed.add_field(name="Features:", value="📦 List your items for sale\n🔍 Browse available auctions\n💎 Find rare equipment", inline=False)
        return embed

class ListItemModal(Modal):
    def __init__(self):
        super().__init__(title="📦 List Item for Auction")

        self.item_name = TextInput(
            label="Item Name",
            placeholder="Enter the item you want to sell...",
            required=True,
            max_length=50
        )
        self.add_item(self.item_name)

        self.price = TextInput(
            label="Starting Price (Zolar)",
            placeholder="Enter starting bid price...",
            required=True,
            max_length=10
        )
        self.add_item(self.price)

    async def on_submit(self, interaction: Interaction):
        user_data = get_user_data(interaction.user.id)
        item = self.item_name.value

        try:
            price = int(self.price.value)
        except ValueError:
            await interaction.response.send_message("❌ Please enter a valid price!", ephemeral=True)
            return

        if item not in user_data["inventory"]:
            await interaction.response.send_message("❌ You don't own this item!", ephemeral=True)
            return

        if price <= 0:
            await interaction.response.send_message("❌ Price must be positive!", ephemeral=True)
            return

        # Remove item from inventory (simplified for now)
        user_data["inventory"].remove(item)
        save_data(data)

        embed = Embed(
            title="✅ Item Listed!",
            description=f"Listed **{item}** for {price} Zolar starting bid!",
            color=discord.Color.green()
        )
        await interaction.response.send_message(embed=embed, ephemeral=True)

@tree.command(name="auction", description="🏛️ Access the auction house")
async def auction(interaction: Interaction):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    view = AuctionView(interaction.user.id)
    embed = view.create_embed()
    await interaction.response.send_message(embed=embed, view=view)

# -------- DUEL SYSTEM --------
@tree.command(name="duel", description="⚔️ Challenge another player to a duel")
async def duel(interaction: Interaction, opponent: discord.Member, bet: int = 0):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    if opponent.bot:
        await interaction.response.send_message("❌ You can't duel bots!", ephemeral=True)
        return

    if opponent.id == interaction.user.id:
        await interaction.response.send_message("❌ You can't duel yourself!", ephemeral=True)
        return

    if check_user_ban(opponent.id):
        await interaction.response.send_message("❌ That user is banned!", ephemeral=True)
        return

    challenger_data = get_user_data(interaction.user.id)
    opponent_data = get_user_data(opponent.id)

    if bet > 0:
        if challenger_data["zolar"] < bet:
            await interaction.response.send_message("❌ You don't have enough Zolar for this bet!", ephemeral=True)
            return
        if opponent_data["zolar"] < bet:
            await interaction.response.send_message("❌ Your opponent doesn't have enough Zolar for this bet!", ephemeral=True)
            return

    view = DuelAcceptView(interaction.user.id, opponent.id, bet)
    embed = Embed(
        title="⚔️ Duel Challenge!",
        description=f"{interaction.user.mention} challenges {opponent.mention} to a duel!",
        color=discord.Color.red()
    )
    embed.add_field(name="Challenger Power", value=challenger_data["power"], inline=True)
    embed.add_field(name="Opponent Power", value=opponent_data["power"], inline=True)
    if bet > 0:
        embed.add_field(name="Bet Amount", value=f"{bet} Zolar", inline=True)

    await interaction.response.send_message(embed=embed, view=view)

class DuelAcceptView(View):
    def __init__(self, challenger_id, opponent_id, bet):
        super().__init__(timeout=60)
        self.challenger_id = challenger_id
        self.opponent_id = opponent_id
        self.bet = bet

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.opponent_id

    @discord.ui.button(label="⚔️ Accept Duel", style=ButtonStyle.red)
    async def accept_duel(self, interaction: Interaction, button: Button):
        challenger = interaction.guild.get_member(self.challenger_id)
        opponent = interaction.user

        challenger_data = get_user_data(self.challenger_id)
        opponent_data = get_user_data(self.opponent_id)

        # Battle calculation
        challenger_power = challenger_data["power"]
        opponent_power = opponent_data["power"]

        # Add some randomness
        challenger_roll = challenger_power + random.randint(-50, 50)
        opponent_roll = opponent_power + random.randint(-50, 50)

        if challenger_roll > opponent_roll:
            winner = challenger
            loser = opponent
            winner_data = challenger_data
            loser_data = opponent_data
        else:
            winner = opponent
            loser = challenger
            winner_data = opponent_data
            loser_data = challenger_data

        # Handle betting
        if self.bet > 0:
            loser_data["zolar"] -= self.bet
            winner_data["zolar"] += self.bet

        # Update stats
        winner_data["stats"]["wins"] += 1
        loser_data["stats"]["losses"] += 1

        # XP rewards
        await add_xp(winner.id, 30)
        await add_xp(loser.id, 10)

        save_data(data)

        embed = Embed(
            title="⚔️ Duel Results!",
            description=f"🎉 **{winner.display_name}** wins the duel!",
            color=discord.Color.green()
        )
        embed.add_field(name="Final Scores", value=f"{challenger.display_name}: {challenger_roll}\n{opponent.display_name}: {opponent_roll}", inline=False)

        if self.bet > 0:
            embed.add_field(name="Winnings", value=f"{winner.display_name} wins {self.bet} Zolar!", inline=False)

        embed.add_field(name="XP Gained", value=f"{winner.display_name}: +30 XP\n{loser.display_name}: +10 XP", inline=False)

        await interaction.response.edit_message(embed=embed, view=None)

# -------- ADVANCED POKER SYSTEM --------
class AdvancedPokerView(View):
    def __init__(self, user_id, bet):
        super().__init__(timeout=300)
        self.user_id = user_id
        self.bet = bet
        self.player_cards = self.deal_cards(2)
        self.community_cards = self.deal_cards(5)
        self.current_round = "pre_flop"
        self.pot = bet
        self.folded = False

    def deal_cards(self, num):
        suits = ["♠️", "♥️", "♦️", "♣️"]
        ranks = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
        deck = [f"{rank}{suit}" for suit in suits for rank in ranks]
        return random.sample(deck, num)

    async def interaction_check(self, interaction: Interaction) -> bool:
        return interaction.user.id == self.user_id

    @discord.ui.button(label="💰 Raise", style=ButtonStyle.green)
    async def raise_bet(self, interaction: Interaction, button: Button):
        if self.folded:
            await interaction.response.send_message("❌ You've already folded!", ephemeral=True)
            return

        modal = RaiseModal(self)
        await interaction.response.send_modal(modal)

    @discord.ui.button(label="✅ Call", style=ButtonStyle.blurple)
    async def call_bet(self, interaction: Interaction, button: Button):
        if self.folded:
            await interaction.response.send_message("❌ You've already folded!", ephemeral=True)
            return

        user_data = get_user_data(self.user_id)
        call_amount = 50  # Fixed call amount for simplicity

        if user_data["zolar"] < call_amount:
            await interaction.response.send_message("❌ Not enough Zolar to call!", ephemeral=True)
            return

        user_data["zolar"] -= call_amount
        self.pot += call_amount
        save_data(data)

        self.advance_round()
        embed = self.create_embed()
        await interaction.response.edit_message(embed=embed, view=self)

    @discord.ui.button(label="❌ Fold", style=ButtonStyle.red)
    async def fold_hand(self, interaction: Interaction, button: Button):
        self.folded = True

        embed = Embed(
            title="❌ Hand Folded",
            description=f"You folded and lost {self.bet} Zolar from the pot.",
            color=discord.Color.red()
        )
        embed.add_field(name="Your Cards:", value=" ".join(self.player_cards), inline=False)
        await interaction.response.edit_message(embed=embed, view=None)

    @discord.ui.button(label="🎯 All-In", style=ButtonStyle.gray)
    async def all_in(self, interaction: Interaction, button: Button):
        if self.folded:
            await interaction.response.send_message("❌ You've already folded!", ephemeral=True)
            return

        user_data = get_user_data(self.user_id)
        all_in_amount = user_data["zolar"]

        if all_in_amount <= 0:
            await interaction.response.send_message("❌ You have no Zolar to bet!", ephemeral=True)
            return

        user_data["zolar"] = 0
        self.pot += all_in_amount
        save_data(data)

        # Force showdown
        self.current_round = "showdown"
        result = self.evaluate_hand()

        embed = Embed(
            title="🎯 ALL-IN SHOWDOWN!",
            description=result,
            color=discord.Color.gold()
        )
        await interaction.response.edit_message(embed=embed, view=None)

    def advance_round(self):
        if self.current_round == "pre_flop":
            self.current_round = "flop"
        elif self.current_round == "flop":
            self.current_round = "turn"
        elif self.current_round == "turn":
            self.current_round = "river"
        elif self.current_round == "river":
            self.current_round = "showdown"
            # Auto-evaluate at showdown
            result = self.evaluate_hand()
            return result

    def evaluate_hand(self):
        # Simplified hand evaluation
        user_data = get_user_data(self.user_id)

        # Random win chance based on pot size (simplified)
        win_chance = min(80, 30 + (self.pot // 100))
        won = random.randint(1, 100) <= win_chance

        if won:
            winnings = int(self.pot * 1.8)  # House edge
            user_data["zolar"] += winnings
            result = f"🎉 You won the pot!\nWinnings: {winnings} Zolar"
        else:
            result = f"💀 You lost the hand!\nLost: {self.pot} Zolar from pot"

        save_data(data)
        return result

    def create_embed(self):
        embed = Embed(title="🎰 Advanced Poker", color=discord.Color.purple())
        embed.add_field(name="Your Cards:", value=" ".join(self.player_cards), inline=False)

        # Show community cards based on round
        if self.current_round == "pre_flop":
            community_display = "🂠 🂠 🂠 🂠 🂠"
        elif self.current_round == "flop":
            community_display = " ".join(self.community_cards[:3]) + " 🂠 🂠"
        elif self.current_round == "turn":
            community_display = " ".join(self.community_cards[:4]) + " 🂠"
        else:
            community_display = " ".join(self.community_cards)

        embed.add_field(name="Community Cards:", value=community_display, inline=False)
        embed.add_field(name="Current Pot:", value=f"{self.pot} Zolar", inline=True)
        embed.add_field(name="Round:", value=self.current_round.replace("_", " ").title(), inline=True)

        if self.current_round == "showdown":
            result = self.evaluate_hand()
            embed.add_field(name="Result:", value=result, inline=False)

        return embed

class RaiseModal(Modal):
    def __init__(self, poker_view):
        super().__init__(title="💰 Raise Bet")
        self.poker_view = poker_view

        self.raise_amount = TextInput(
            label="Raise Amount (Zolar)",
            placeholder="Enter amount to raise...",
            required=True,
            max_length=10
        )
        self.add_item(self.raise_amount)

    async def on_submit(self, interaction: Interaction):
        try:
            amount = int(self.raise_amount.value)
        except ValueError:
            await interaction.response.send_message("❌ Please enter a valid number!", ephemeral=True)
            return

        user_data = get_user_data(interaction.user.id)

        if amount <= 0:
            await interaction.response.send_message("❌ Raise amount must be positive!", ephemeral=True)
            return

        if user_data["zolar"] < amount:
            await interaction.response.send_message("❌ You don't have enough Zolar!", ephemeral=True)
            return

        user_data["zolar"] -= amount
        self.poker_view.pot += amount
        save_data(data)

        self.poker_view.advance_round()
        embed = self.poker_view.create_embed()
        await interaction.response.edit_message(embed=embed, view=self.poker_view)

# -------- MULTIPLAYER LOBBY SYSTEM --------
LOBBY_DATA = "lobby_data.json"

def load_lobbies():
    if not os.path.exists(LOBBY_DATA):
        with open(LOBBY_DATA, "w") as f: 
            json.dump({}, f)
    with open(LOBBY_DATA, "r") as f: 
        return json.load(f)

def save_lobbies(lobby_data):
    with open(LOBBY_DATA, "w") as f: 
        json.dump(lobby_data, f, indent=2)

class LobbyView(View):
    def __init__(self, user_id, lobby_name):
        super().__init__(timeout=300)
        self.user_id = user_id
        self.lobby_name = lobby_name

    async def interaction_check(self, interaction: Interaction) -> bool:
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)
        if not lobby:
            return False
        return interaction.user.id in lobby["members"] or interaction.user.id == lobby["owner"]

    @discord.ui.button(label="🎮 Start Game", style=ButtonStyle.green)
    async def start_game(self, interaction: Interaction, button: Button):
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)

        if not lobby or interaction.user.id != lobby["owner"]:
            await interaction.response.send_message("❌ Only the lobby owner can start games!", ephemeral=True)
            return

        if len(lobby["members"]) < 2:
            await interaction.response.send_message("❌ Need at least 2 players to start!", ephemeral=True)
            return

        view = LobbyGameSelectView(self.user_id, self.lobby_name)
        embed = view.create_embed()
        await interaction.response.edit_message(embed=embed, view=view)

    @discord.ui.button(label="📊 Lobby Info", style=ButtonStyle.blurple)
    async def lobby_info(self, interaction: Interaction, button: Button):
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)

        if not lobby:
            await interaction.response.send_message("❌ Lobby not found!", ephemeral=True)
            return

        member_list = []
        for member_id in lobby["members"]:
            member = interaction.guild.get_member(int(member_id))
            if member:
                role = "👑 Owner" if member_id == lobby["owner"] else "👤 Member"
                member_list.append(f"{role} {member.display_name}")

        embed = Embed(title=f"🎮 Lobby: {self.lobby_name}", color=discord.Color.blue())
        embed.add_field(name="Members:", value="\n".join(member_list), inline=False)
        embed.add_field(name="Created:", value=lobby.get("created_at", "Unknown"), inline=True)
        embed.add_field(name="Max Players:", value="6", inline=True)

        await interaction.response.send_message(embed=embed, ephemeral=True)

    @discord.ui.button(label="🚪 Leave Lobby", style=ButtonStyle.red)
    async def leave_lobby(self, interaction: Interaction, button: Button):
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)

        if not lobby:
            await interaction.response.send_message("❌ Lobby not found!", ephemeral=True)
            return

        user_id_str = str(interaction.user.id)

        if user_id_str in lobby["members"]:
            lobby["members"].remove(user_id_str)

            # If owner leaves, transfer ownership or delete lobby
            if user_id_str == lobby["owner"]:
                if lobby["members"]:
                    lobby["owner"] = lobby["members"][0]
                    save_lobbies(lobbies)
                    await interaction.response.send_message("✅ Left lobby. Ownership transferred.", ephemeral=True)
                else:
                    del lobbies[self.lobby_name]
                    save_lobbies(lobbies)
                    await interaction.response.send_message("✅ Left lobby. Lobby deleted (was empty).", ephemeral=True)
            else:
                save_lobbies(lobbies)
                await interaction.response.send_message("✅ Left the lobby.", ephemeral=True)
        else:
            await interaction.response.send_message("❌ You're not in this lobby!", ephemeral=True)

    def create_embed(self):
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)

        if not lobby:
            return Embed(title="❌ Lobby Not Found", color=discord.Color.red())

        embed = Embed(title=f"🎮 Lobby: {self.lobby_name}", color=discord.Color.green())
        embed.add_field(name="Players:", value=f"{len(lobby['members'])}/6", inline=True)
        embed.add_field(name="Owner:", value=f"<@{lobby['owner']}>", inline=True)
        embed.add_field(name="Status:", value="Waiting for players", inline=True)

        return embed

class LobbyGameSelectView(View):
    def __init__(self, user_id, lobby_name):
        super().__init__(timeout=300)
        self.user_id = user_id
        self.lobby_name = lobby_name

    async def interaction_check(self, interaction: Interaction) -> bool:
        lobbies = load_lobbies()
        lobby = lobbies.get(self.lobby_name)
        return lobby and interaction.user.id == int(lobby["owner"])

    @discord.ui.select(
        placeholder="Choose a game to play...",
        options=[
            SelectOption(label="🃏 Multiplayer Blackjack", description="Play blackjack together", value="blackjack"),
            SelectOption(label="🎰 Poker Tournament", description="Texas Hold'em poker", value="poker"),
            SelectOption(label="🎲 Dice Battle", description="Roll dice competitively", value="dice")
        ]
    )
    async def select_game(self, interaction: Interaction, select: Select):
        game_type = select.values[0]
        lobbies = load_lobbies()
        lobby = lobbies[self.lobby_name]

        # Start the selected game
        if game_type == "blackjack":
            view = MultiplayerBlackjackView(lobby["members"], self.lobby_name)
        elif game_type == "poker":
            view = MultiplayerPokerView(lobby["members"], self.lobby_name)
        elif game_type == "dice":
            view = MultiplayerDiceView(lobby["members"], self.lobby_name)

        embed = view.create_embed()

        # Notify all lobby members
        for member_id in lobby["members"]:
            member = interaction.guild.get_member(int(member_id))
            if member and member.id != interaction.user.id:
                try:
                    await member.send(f"🎮 Game started in lobby '{self.lobby_name}'! Game: {game_type.title()}")
                except:
                    pass

        await interaction.response.edit_message(embed=embed, view=view)

    def create_embed(self):
        embed = Embed(title="🎮 Select Game", description="Choose a game for the lobby to play!", color=discord.Color.purple())
        embed.add_field(name="Available Games:", value="🃏 Multiplayer Blackjack\n🎰 Poker Tournament\n🎲 Dice Battle", inline=False)
        return embed

class MultiplayerBlackjackView(View):
    def __init__(self, members, lobby_name):
        super().__init__(timeout=300)
        self.members = members
        self.lobby_name = lobby_name
        self.player_hands = {}
        self.game_started = False

    async def interaction_check(self, interaction: Interaction) -> bool:
        return str(interaction.user.id) in self.members

    @discord.ui.button(label="🎴 Deal Cards", style=ButtonStyle.green)
    async def deal_cards(self, interaction: Interaction, button: Button):
        if self.game_started:
            await interaction.response.send_message("❌ Game already started!", ephemeral=True)
            return

        self.game_started = True

        # Deal cards to all players
        for member_id in self.members:
            self.player_hands[member_id] = random.randint(16, 21)

        embed = self.create_game_embed()
        await interaction.response.edit_message(embed=embed, view=self)

    @discord.ui.button(label="🏆 Show Results", style=ButtonStyle.blurple)
    async def show_results(self, interaction: Interaction, button: Button):
        if not self.game_started:
            await interaction.response.send_message("❌ Deal cards first!", ephemeral=True)
            return

        # Determine winner
        valid_hands = {k: v for k, v in self.player_hands.items() if v <= 21}

        if not valid_hands:
            result = "💥 Everyone busted! No winner."
        else:
            winner_id = max(valid_hands, key=valid_hands.get)
            winner = interaction.guild.get_member(int(winner_id))
            result = f"🏆 {winner.display_name if winner else 'Unknown'} wins with {valid_hands[winner_id]}!"

            # Reward winner
            winner_data = get_user_data(int(winner_id))
            winner_data["zolar"] += 100 * len(self.members)
            save_data(data)

        embed = Embed(title="🃏 Multiplayer Blackjack Results", description=result, color=discord.Color.gold())

        hands_text = []
        for member_id in self.members:
            member = interaction.guild.get_member(int(member_id))
            hand = self.player_hands.get(member_id, 0)
            status = "💥 Bust" if hand > 21 else f"✅ {hand}"
            hands_text.append(f"{member.display_name if member else 'Unknown'}: {status}")

        embed.add_field(name="All Hands:", value="\n".join(hands_text), inline=False)

        await interaction.response.edit_message(embed=embed, view=None)

    def create_embed(self):
        embed = Embed(title="🃏 Multiplayer Blackjack", description=f"Lobby: {self.lobby_name}", color=discord.Color.blue())
        embed.add_field(name="Players:", value=f"{len(self.members)} players ready", inline=False)

        if self.game_started:
            embed.add_field(name="Game Status:", value="🎴 Cards dealt! Check results when ready.", inline=False)
        else:
            embed.add_field(name="Game Status:", value="⏳ Waiting to deal cards...", inline=False)

        return embed

    def create_game_embed(self):
        embed = Embed(title="🃏 Multiplayer Blackjack - Cards Dealt!", color=discord.Color.green())

        hands_text = []
        for member_id in self.members:
            member = bot.get_guild(list(bot.guilds)[0].id).get_member(int(member_id))  # Simplified guild lookup
            hand = self.player_hands.get(member_id, 0)
            hands_text.append(f"{member.display_name if member else 'Unknown'}: {hand}")

        embed.add_field(name="Player Hands:", value="\n".join(hands_text), inline=False)
        embed.add_field(name="Next:", value="Click 'Show Results' to see who wins!", inline=False)

        return embed

class MultiplayerPokerView(View):
    def __init__(self, members, lobby_name):
        super().__init__(timeout=300)
        self.members = members
        self.lobby_name = lobby_name

    def create_embed(self):
        embed = Embed(title="🎰 Multiplayer Poker", description="Coming in future update!", color=discord.Color.purple())
        return embed

class MultiplayerDiceView(View):
    def __init__(self, members, lobby_name):
        super().__init__(timeout=300)
        self.members = members
        self.lobby_name = lobby_name

    def create_embed(self):
        embed = Embed(title="🎲 Multiplayer Dice", description="Coming in future update!", color=discord.Color.orange())
        return embed

@tree.command(name="lobby", description="🎮 Manage multiplayer game lobbies")
async def lobby_command(interaction: Interaction, action: str, name: str = None, pin: str = None):
    if check_user_ban(interaction.user.id):
        await interaction.response.send_message("❌ You are banned from using this bot!", ephemeral=True)
        return

    lobbies = load_lobbies()

    if action.lower() == "create":
        if not name:
            await interaction.response.send_message("❌ Please provide a lobby name: `/lobby create MyLobby`", ephemeral=True)
            return

        if name in lobbies:
            await interaction.response.send_message("❌ Lobby name already exists!", ephemeral=True)
            return

        # Create new lobby
        lobbies[name] = {
            "owner": str(interaction.user.id),
            "members": [str(interaction.user.id)],
            "pin": pin or "0000",
            "created_at": datetime.datetime.now().isoformat(),
            "max_players": 6
        }

        save_lobbies(lobbies)

        embed = Embed(
            title="✅ Lobby Created!",
            description=f"Created lobby: **{name}**",
            color=discord.Color.green()
        )
        embed.add_field(name="PIN:", value=pin or "0000", inline=True)
        embed.add_field(name="Owner:", value=interaction.user.display_name, inline=True)

        view = LobbyView(interaction.user.id, name)
        embed_lobby = view.create_embed()

        await interaction.response.send_message(embed=embed, ephemeral=True)
        await interaction.followup.send(embed=embed_lobby, view=view)

    elif action.lower() == "join":
        if not name:
            await interaction.response.send_message("❌ Please provide a lobby name: `/lobby join LobbyName`", ephemeral=True)
            return

        if name not in lobbies:
            await interaction.response.send_message("❌ Lobby not found!", ephemeral=True)
            return

        lobby = lobbies[name]

        # Check PIN if provided
        if lobby.get("pin") and lobby["pin"] != "0000":
            if not pin or pin != lobby["pin"]:
                await interaction.response.send_message("❌ Incorrect PIN!", ephemeral=True)
                return

        user_id_str = str(interaction.user.id)

        if user_id_str in lobby["members"]:
            await interaction.response.send_message("❌ You're already in this lobby!", ephemeral=True)
            return

        if len(lobby["members"]) >= lobby["max_players"]:
            await interaction.response.send_message("❌ Lobby is full!", ephemeral=True)
            return

        # Join lobby
        lobby["members"].append(user_id_str)
        save_lobbies(lobbies)

        embed = Embed(
            title="✅ Joined Lobby!",
            description=f"Joined lobby: **{name}**",
            color=discord.Color.green()
        )

        view = LobbyView(interaction.user.id, name)
        embed_lobby = view.create_embed()

        await interaction.response.send_message(embed=embed, ephemeral=True)
        await interaction.followup.send(embed=embed_lobby, view=view)

    else:
        await interaction.response.send_message("❌ Invalid action! Use: `/lobby create LobbyName` or `/lobby join LobbyName [pin]`", ephemeral=True)

#The code implements advanced poker and multiplayer lobby systems.
bot.run(TOKEN)
