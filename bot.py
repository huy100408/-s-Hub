import discord
from discord.ext import commands
import json
import sqlite3
import asyncio
import random
import datetime
from typing import Dict, List, Optional, Tuple
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Bot configuration
ADMIN_IDS = [1355906051442216981, 878991087920902274]
RANKS = {
    0: "Peasant",
    1: "Knight", 
    2: "Baron",
    3: "Duke",
    4: "Prince",
    5: "King"
}
RANK_XP_REQUIREMENTS = {
    0: 0,      # Peasant
    1: 100,    # Knight
    2: 500,    # Baron
    3: 1500,   # Duke
    4: 3000,   # Prince
    5: 5000    # King
}

# Bot colors for embeds
COLORS = {
    'primary': 0x7289DA,
    'success': 0x00FF00,
    'error': 0xFF0000,
    'warning': 0xFFFF00,
    'info': 0x00FFFF,
    'gold': 0xFFD700
}

class DatabaseManager:
    """Handles all database operations for the bot"""
    
    def __init__(self, db_path: str = "empire_bot.db"):
        self.db_path = db_path
        self.init_database()
    
    def init_database(self):
        """Initialize the database with required tables"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Users table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS users (
                    user_id INTEGER PRIMARY KEY,
                    username TEXT,
                    xp INTEGER DEFAULT 0,
                    rank INTEGER DEFAULT 0,
                    zolar INTEGER DEFAULT 100,
                    last_daily DATE,
                    total_gambled INTEGER DEFAULT 0,
                    total_won INTEGER DEFAULT 0
                )
            ''')
            
            # Items table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS items (
                    item_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    description TEXT,
                    value INTEGER DEFAULT 0,
                    rarity TEXT DEFAULT 'common'
                )
            ''')
            
            # User inventory table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS user_inventory (
                    user_id INTEGER,
                    item_id INTEGER,
                    quantity INTEGER DEFAULT 1,
                    FOREIGN KEY (user_id) REFERENCES users(user_id),
                    FOREIGN KEY (item_id) REFERENCES items(item_id)
                )
            ''')
            
            # Auctions table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS auctions (
                    auction_id INTEGER PRIMARY KEY AUTOINCREMENT,
                    seller_id INTEGER,
                    item_name TEXT,
                    starting_price INTEGER,
                    current_price INTEGER,
                    highest_bidder INTEGER,
                    end_time TIMESTAMP,
                    active BOOLEAN DEFAULT TRUE,
                    FOREIGN KEY (seller_id) REFERENCES users(user_id)
                )
            ''')
            
            # Gambling settings table
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT
                )
            ''')
            
            # Insert default settings
            cursor.execute('INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)', 
                         ('gambling_enabled', 'true'))
            
            conn.commit()
    
    def get_user(self, user_id: int, username: str = None) -> Dict:
        """Get user data, create if doesn't exist"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT * FROM users WHERE user_id = ?', (user_id,))
            user = cursor.fetchone()
            
            if not user:
                cursor.execute('''
                    INSERT INTO users (user_id, username, xp, rank, zolar) 
                    VALUES (?, ?, ?, ?, ?)
                ''', (user_id, username or str(user_id), 0, 0, 100))
                conn.commit()
                return {
                    'user_id': user_id,
                    'username': username or str(user_id),
                    'xp': 0,
                    'rank': 0,
                    'zolar': 100,
                    'last_daily': None,
                    'total_gambled': 0,
                    'total_won': 0
                }
            
            return {
                'user_id': user[0],
                'username': user[1],
                'xp': user[2],
                'rank': user[3],
                'zolar': user[4],
                'last_daily': user[5],
                'total_gambled': user[6],
                'total_won': user[7]
            }
    
    def update_user(self, user_id: int, **kwargs):
        """Update user data"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            
            # Build dynamic update query
            fields = []
            values = []
            for key, value in kwargs.items():
                if key in ['xp', 'rank', 'zolar', 'last_daily', 'total_gambled', 'total_won', 'username']:
                    fields.append(f"{key} = ?")
                    values.append(value)
            
            if fields:
                query = f"UPDATE users SET {', '.join(fields)} WHERE user_id = ?"
                values.append(user_id)
                cursor.execute(query, values)
                conn.commit()
    
    def get_setting(self, key: str) -> str:
        """Get a setting value"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('SELECT value FROM settings WHERE key = ?', (key,))
            result = cursor.fetchone()
            return result[0] if result else None
    
    def set_setting(self, key: str, value: str):
        """Set a setting value"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)', 
                         (key, value))
            conn.commit()

class EmpireBot(commands.Bot):
    """Main bot class"""
    
    def __init__(self):
        intents = discord.Intents.default()
        intents.message_content = True
        super().__init__(command_prefix='!', intents=intents)
        
        self.db = DatabaseManager()
        self.active_games = {}  # Store active gambling games
        
    async def on_ready(self):
        """Called when bot is ready"""
        logger.info(f'{self.user} has connected to Discord!')
        await self.change_presence(activity=discord.Game(name="Managing the Empire | !help"))
    
    async def on_message(self, message):
        """Handle XP gain from messages"""
        if message.author.bot:
            return
        
        # Award XP for messages (1-3 XP per message)
        user_data = self.db.get_user(message.author.id, message.author.name)
        xp_gain = random.randint(1, 3)
        new_xp = user_data['xp'] + xp_gain
        
        # Check for rank up
        old_rank = user_data['rank']
        new_rank = self.calculate_rank(new_xp)
        
        self.db.update_user(message.author.id, xp=new_xp, rank=new_rank)
        
        # Send rank up message
        if new_rank > old_rank:
            embed = discord.Embed(
                title="🎉 Rank Up!",
                description=f"Congratulations {message.author.mention}! You've been promoted to **{RANKS[new_rank]}**!",
                color=COLORS['success']
            )
            embed.add_field(name="New Rank", value=RANKS[new_rank], inline=True)
            embed.add_field(name="XP", value=f"{new_xp:,}", inline=True)
            await message.channel.send(embed=embed)
        
        await self.process_commands(message)
    
    def calculate_rank(self, xp: int) -> int:
        """Calculate rank based on XP"""
        for rank in sorted(RANK_XP_REQUIREMENTS.keys(), reverse=True):
            if xp >= RANK_XP_REQUIREMENTS[rank]:
                return rank
        return 0
    
    def is_admin(self, user_id: int) -> bool:
        """Check if user is an admin"""
        return user_id in ADMIN_IDS

# Initialize bot
bot = EmpireBot()

# Basic Commands
@bot.command(name='profile', aliases=['p', 'stats'])
async def profile(ctx, member: discord.Member = None):
    """Show user profile"""
    user = member or ctx.author
    user_data = bot.db.get_user(user.id, user.name)
    
    rank_name = RANKS[user_data['rank']]
    next_rank = user_data['rank'] + 1
    
    embed = discord.Embed(
        title=f"👑 {user.display_name}'s Profile",
        color=COLORS['primary']
    )
    embed.set_thumbnail(url=user.avatar.url if user.avatar else user.default_avatar.url)
    
    embed.add_field(name="🏆 Rank", value=rank_name, inline=True)
    embed.add_field(name="⭐ XP", value=f"{user_data['xp']:,}", inline=True)
    embed.add_field(name="💰 Zolar", value=f"{user_data['zolar']:,}", inline=True)
    
    if next_rank <= 5:
        xp_needed = RANK_XP_REQUIREMENTS[next_rank] - user_data['xp']
        embed.add_field(name="📈 Next Rank", value=f"{RANKS[next_rank]}\n({xp_needed:,} XP needed)", inline=True)
    
    embed.add_field(name="🎲 Gambling Stats", 
                   value=f"Gambled: {user_data['total_gambled']:,}\nWon: {user_data['total_won']:,}", 
                   inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='balance', aliases=['bal', 'zolar'])
async def balance(ctx, member: discord.Member = None):
    """Check Zolar balance"""
    user = member or ctx.author
    user_data = bot.db.get_user(user.id, user.name)
    
    embed = discord.Embed(
        title="💰 Zolar Balance",
        description=f"{user.display_name} has **{user_data['zolar']:,}** Zolar",
        color=COLORS['gold']
    )
    
    await ctx.send(embed=embed)

@bot.command(name='daily')
async def daily(ctx):
    """Claim daily Zolar reward"""
    user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    today = datetime.date.today()
    
    if user_data['last_daily'] == str(today):
        embed = discord.Embed(
            title="⏰ Daily Reward",
            description="You've already claimed your daily reward today! Come back tomorrow.",
            color=COLORS['warning']
        )
        await ctx.send(embed=embed)
        return
    
    # Calculate reward based on rank
    base_reward = 50
    rank_bonus = user_data['rank'] * 25
    total_reward = base_reward + rank_bonus
    
    new_zolar = user_data['zolar'] + total_reward
    bot.db.update_user(ctx.author.id, zolar=new_zolar, last_daily=str(today))
    
    embed = discord.Embed(
        title="🎁 Daily Reward Claimed!",
        description=f"You received **{total_reward:,}** Zolar!",
        color=COLORS['success']
    )
    embed.add_field(name="Base Reward", value=f"{base_reward:,}", inline=True)
    embed.add_field(name="Rank Bonus", value=f"{rank_bonus:,}", inline=True)
    embed.add_field(name="New Balance", value=f"{new_zolar:,}", inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='transfer', aliases=['pay', 'give'])
async def transfer(ctx, member: discord.Member, amount: int):
    """Transfer Zolar to another user"""
    if amount <= 0:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Amount",
            description="Amount must be greater than 0.",
            color=COLORS['error']
        ))
        return
    
    if member.bot:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Target",
            description="You cannot transfer Zolar to bots.",
            color=COLORS['error']
        ))
        return
    
    sender_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    
    if sender_data['zolar'] < amount:
        await ctx.send(embed=discord.Embed(
            title="❌ Insufficient Funds",
            description=f"You don't have enough Zolar. You have {sender_data['zolar']:,} Zolar.",
            color=COLORS['error']
        ))
        return
    
    receiver_data = bot.db.get_user(member.id, member.name)
    
    # Perform transfer
    bot.db.update_user(ctx.author.id, zolar=sender_data['zolar'] - amount)
    bot.db.update_user(member.id, zolar=receiver_data['zolar'] + amount)
    
    embed = discord.Embed(
        title="💸 Transfer Successful",
        description=f"{ctx.author.mention} sent **{amount:,}** Zolar to {member.mention}!",
        color=COLORS['success']
    )
    
    await ctx.send(embed=embed)

# Gambling Commands
class BlackjackGame:
    """Blackjack game logic"""
    
    def __init__(self, player_id: int, bet: int):
        self.player_id = player_id
        self.bet = bet
        self.deck = self.create_deck()
        self.player_hand = []
        self.dealer_hand = []
        self.game_over = False
        self.player_won = False
        
        # Deal initial cards
        self.player_hand.append(self.draw_card())
        self.dealer_hand.append(self.draw_card())
        self.player_hand.append(self.draw_card())
        self.dealer_hand.append(self.draw_card())
    
    def create_deck(self):
        """Create a shuffled deck"""
        suits = ['♠', '♥', '♦', '♣']
        ranks = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K']
        deck = [(rank, suit) for suit in suits for rank in ranks]
        random.shuffle(deck)
        return deck
    
    def draw_card(self):
        """Draw a card from the deck"""
        return self.deck.pop()
    
    def calculate_hand_value(self, hand):
        """Calculate the value of a hand"""
        value = 0
        aces = 0
        
        for card in hand:
            rank = card[0]
            if rank in ['J', 'Q', 'K']:
                value += 10
            elif rank == 'A':
                aces += 1
                value += 11
            else:
                value += int(rank)
        
        # Adjust for aces
        while value > 21 and aces > 0:
            value -= 10
            aces -= 1
        
        return value
    
    def format_hand(self, hand, hide_dealer=False):
        """Format hand for display"""
        if hide_dealer and len(hand) > 1:
            return f"{hand[0][0]}{hand[0][1]}, ??", self.calculate_hand_value([hand[0]])
        
        hand_str = ", ".join([f"{card[0]}{card[1]}" for card in hand])
        return hand_str, self.calculate_hand_value(hand)
    
    def hit(self):
        """Player hits"""
        self.player_hand.append(self.draw_card())
        if self.calculate_hand_value(self.player_hand) > 21:
            self.game_over = True
            self.player_won = False
    
    def stand(self):
        """Player stands, dealer plays"""
        while self.calculate_hand_value(self.dealer_hand) < 17:
            self.dealer_hand.append(self.draw_card())
        
        player_value = self.calculate_hand_value(self.player_hand)
        dealer_value = self.calculate_hand_value(self.dealer_hand)
        
        if dealer_value > 21:
            self.player_won = True
        elif player_value > dealer_value:
            self.player_won = True
        else:
            self.player_won = False
        
        self.game_over = True

class BlackjackView(discord.ui.View):
    """Discord UI for Blackjack"""
    
    def __init__(self, game: BlackjackGame):
        super().__init__(timeout=60)
        self.game = game
    
    @discord.ui.button(label='Hit', style=discord.ButtonStyle.primary, emoji='👊')
    async def hit(self, interaction: discord.Interaction, button: discord.ui.Button):
        if interaction.user.id != self.game.player_id:
            await interaction.response.send_message("This isn't your game!", ephemeral=True)
            return
        
        self.game.hit()
        await self.update_game(interaction)
    
    @discord.ui.button(label='Stand', style=discord.ButtonStyle.secondary, emoji='✋')
    async def stand(self, interaction: discord.Interaction, button: discord.ui.Button):
        if interaction.user.id != self.game.player_id:
            await interaction.response.send_message("This isn't your game!", ephemeral=True)
            return
        
        self.game.stand()
        await self.update_game(interaction)
    
    async def update_game(self, interaction: discord.Interaction):
        """Update the game display"""
        if self.game.game_over:
            # Game ended, show final results
            player_hand, player_value = self.game.format_hand(self.game.player_hand)
            dealer_hand, dealer_value = self.game.format_hand(self.game.dealer_hand)
            
            embed = discord.Embed(
                title="🃏 Blackjack - Game Over",
                color=COLORS['success'] if self.game.player_won else COLORS['error']
            )
            
            embed.add_field(name="Your Hand", value=f"{player_hand}\n**Value: {player_value}**", inline=True)
            embed.add_field(name="Dealer Hand", value=f"{dealer_hand}\n**Value: {dealer_value}**", inline=True)
            
            if self.game.player_won:
                winnings = self.game.bet * 2
                embed.add_field(name="Result", value=f"🎉 You won!\n**+{winnings:,}** Zolar", inline=False)
                
                # Update user balance
                user_data = bot.db.get_user(self.game.player_id)
                bot.db.update_user(self.game.player_id, 
                                 zolar=user_data['zolar'] + winnings,
                                 total_won=user_data['total_won'] + winnings)
            else:
                embed.add_field(name="Result", value=f"😞 You lost!\n**-{self.game.bet:,}** Zolar", inline=False)
            
            # Disable buttons
            for item in self.children:
                item.disabled = True
            
            await interaction.response.edit_message(embed=embed, view=self)
            
            # Remove from active games
            if self.game.player_id in bot.active_games:
                del bot.active_games[self.game.player_id]
        
        else:
            # Game continues
            player_hand, player_value = self.game.format_hand(self.game.player_hand)
            dealer_hand, dealer_value = self.game.format_hand(self.game.dealer_hand, hide_dealer=True)
            
            embed = discord.Embed(
                title="🃏 Blackjack",
                description=f"**Bet:** {self.game.bet:,} Zolar",
                color=COLORS['primary']
            )
            
            embed.add_field(name="Your Hand", value=f"{player_hand}\n**Value: {player_value}**", inline=True)
            embed.add_field(name="Dealer Hand", value=f"{dealer_hand}\n**Value: {dealer_value}**", inline=True)
            
            if player_value > 21:
                embed.add_field(name="Result", value="💥 Bust! You lose!", inline=False)
                
                # Disable buttons
                for item in self.children:
                    item.disabled = True
                
                # Remove from active games
                if self.game.player_id in bot.active_games:
                    del bot.active_games[self.game.player_id]
            
            await interaction.response.edit_message(embed=embed, view=self)

@bot.command(name='blackjack', aliases=['bj'])
async def blackjack(ctx, bet: int):
    """Start a blackjack game"""
    # Check if gambling is enabled
    if bot.db.get_setting('gambling_enabled') != 'true':
        await ctx.send(embed=discord.Embed(
            title="🚫 Gambling Disabled",
            description="Gambling is currently disabled by an administrator.",
            color=COLORS['error']
        ))
        return
    
    # Check if user already has an active game
    if ctx.author.id in bot.active_games:
        await ctx.send(embed=discord.Embed(
            title="🎲 Active Game",
            description="You already have an active game! Finish it before starting a new one.",
            color=COLORS['warning']
        ))
        return
    
    # Validate bet
    if bet <= 0:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Bet",
            description="Bet must be greater than 0.",
            color=COLORS['error']
        ))
        return
    
    user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    
    if user_data['zolar'] < bet:
        await ctx.send(embed=discord.Embed(
            title="❌ Insufficient Funds",
            description=f"You don't have enough Zolar. You have {user_data['zolar']:,} Zolar.",
            color=COLORS['error']
        ))
        return
    
    # Deduct bet from balance
    bot.db.update_user(ctx.author.id, 
                      zolar=user_data['zolar'] - bet,
                      total_gambled=user_data['total_gambled'] + bet)
    
    # Create game
    game = BlackjackGame(ctx.author.id, bet)
    bot.active_games[ctx.author.id] = game
    
    # Check for blackjack
    player_value = game.calculate_hand_value(game.player_hand)
    if player_value == 21:
        # Blackjack! Instant win
        winnings = int(bet * 2.5)  # 3:2 payout
        bot.db.update_user(ctx.author.id, 
                          zolar=user_data['zolar'] - bet + winnings,
                          total_won=user_data['total_won'] + winnings)
        
        player_hand, _ = game.format_hand(game.player_hand)
        embed = discord.Embed(
            title="🃏 Blackjack - BLACKJACK!",
            description=f"**Bet:** {bet:,} Zolar",
            color=COLORS['success']
        )
        embed.add_field(name="Your Hand", value=f"{player_hand}\n**BLACKJACK!**", inline=True)
        embed.add_field(name="Result", value=f"🎉 Blackjack!\n**+{winnings:,}** Zolar", inline=False)
        
        del bot.active_games[ctx.author.id]
        await ctx.send(embed=embed)
        return
    
    # Create game interface
    view = BlackjackView(game)
    
    player_hand, player_value = game.format_hand(game.player_hand)
    dealer_hand, dealer_value = game.format_hand(game.dealer_hand, hide_dealer=True)
    
    embed = discord.Embed(
        title="🃏 Blackjack",
        description=f"**Bet:** {bet:,} Zolar",
        color=COLORS['primary']
    )
    
    embed.add_field(name="Your Hand", value=f"{player_hand}\n**Value: {player_value}**", inline=True)
    embed.add_field(name="Dealer Hand", value=f"{dealer_hand}\n**Value: {dealer_value}**", inline=True)
    
    await ctx.send(embed=embed, view=view)

# Admin Commands
@bot.command(name='addmoney', aliases=['addzolar'])
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def add_money(ctx, member: discord.Member, amount: int):
    """Add Zolar to a user (Admin only)"""
    user_data = bot.db.get_user(member.id, member.name)
    new_balance = user_data['zolar'] + amount
    
    bot.db.update_user(member.id, zolar=new_balance)
    
    embed = discord.Embed(
        title="💰 Zolar Added",
        description=f"Added **{amount:,}** Zolar to {member.mention}",
        color=COLORS['success']
    )
    embed.add_field(name="New Balance", value=f"{new_balance:,}", inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='removemoney', aliases=['removezolar'])
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def remove_money(ctx, member: discord.Member, amount: int):
    """Remove Zolar from a user (Admin only)"""
    user_data = bot.db.get_user(member.id, member.name)
    new_balance = max(0, user_data['zolar'] - amount)
    
    bot.db.update_user(member.id, zolar=new_balance)
    
    embed = discord.Embed(
        title="💸 Zolar Removed",
        description=f"Removed **{amount:,}** Zolar from {member.mention}",
        color=COLORS['warning']
    )
    embed.add_field(name="New Balance", value=f"{new_balance:,}", inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='setrank')
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def set_rank(ctx, member: discord.Member, rank: int):
    """Set a user's rank (Admin only)"""
    if rank < 0 or rank > 5:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Rank",
            description="Rank must be between 0 and 5.",
            color=COLORS['error']
        ))
        return
    
    bot.db.update_user(member.id, rank=rank)
    
    embed = discord.Embed(
        title="👑 Rank Set",
        description=f"Set {member.mention}'s rank to **{RANKS[rank]}**",
        color=COLORS['success']
    )
    
    await ctx.send(embed=embed)

@bot.command(name='togglegambling')
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def toggle_gambling(ctx):
    """Toggle gambling on/off (Admin only)"""
    current = bot.db.get_setting('gambling_enabled')
    new_value = 'false' if current == 'true' else 'true'
    bot.db.set_setting('gambling_enabled', new_value)
    
    status = "enabled" if new_value == 'true' else "disabled"
    embed = discord.Embed(
        title="🎲 Gambling Status",
        description=f"Gambling has been **{status}**",
        color=COLORS['success'] if new_value == 'true' else COLORS['warning']
    )
    
    await ctx.send(embed=embed)

# Help Command
@bot.command(name='help')
async def help_command(ctx, category: str = None):
    """Show help information"""
    if category is None:
        embed = discord.Embed(
            title="🏰 Empire Bot - Help",
            description="Welcome to the Empire Bot! Here are the available command categories:",
            color=COLORS['primary']
        )
        
        embed.add_field(
            name="📊 Profile & Economy",
            value="`!help profile` - Profile and economy commands",
            inline=False
        )
        
        embed.add_field(
            name="🎲 Gambling",
            value="`!help gambling` - Gambling and mini-games",
            inline=False
        )
        
        if bot.is_admin(ctx.author.id):
            embed.add_field(
                name="🔧 Admin Commands",
                value="`!help admin` - Administrator commands",
                inline=False
            )
        
        embed.set_footer(text="Use !help <category> for detailed information")
        
    elif category.lower() == 'profile':
        embed = discord.Embed(
            title="📊 Profile & Economy Commands",
            color=COLORS['info']
        )
        
        commands_info = [
            ("!profile [user]", "View your or another user's profile"),
            ("!balance [user]", "Check Zolar balance"),
            ("!daily", "Claim daily Zolar reward"),
            ("!transfer <user> <amount>", "Transfer Zolar to another user"),
            ("!leaderboard", "View the top players"),
            ("!redeem <code>", "Redeem a special code for rewards")
        ]
        
        for cmd, desc in commands_info:
            embed.add_field(name=cmd, value=desc, inline=False)
    
    elif category.lower() == 'gambling':
        embed = discord.Embed(
            title="🎲 Gambling Commands",
            color=COLORS['info']
        )
        
        commands_info = [
            ("!blackjack <bet>", "Play blackjack with the dealer"),
            ("!coinflip <bet> <heads/tails>", "Flip a coin and bet on the result"),
            ("!dice <bet> <number>", "Roll dice and bet on the number (1-6)"),
            ("!slots <bet>", "Play the slot machine"),
            ("!roulette <bet> <color/number>", "Play roulette")
        ]
        
        for cmd, desc in commands_info:
            embed.add_field(name=cmd, value=desc, inline=False)
    
    elif category.lower() == 'admin' and bot.is_admin(ctx.author.id):
        embed = discord.Embed(
            title="🔧 Admin Commands",
            color=COLORS['warning']
        )
        
        commands_info = [
            ("!addmoney <user> <amount>", "Add Zolar to a user"),
            ("!removemoney <user> <amount>", "Remove Zolar from a user"),
            ("!setrank <user> <rank>", "Set a user's rank (0-5)"),
            ("!togglegambling", "Enable/disable gambling"),
            ("!createcode <code> <reward>", "Create a redeemable code"),
            ("!serverstats", "View server statistics")
        ]
        
        for cmd, desc in commands_info:
            embed.add_field(name=cmd, value=desc, inline=False)
    
    else:
        embed = discord.Embed(
            title="❌ Unknown Category",
            description="Available categories: `profile`, `gambling`" + (", `admin`" if bot.is_admin(ctx.author.id) else ""),
            color=COLORS['error']
        )
    
    await ctx.send(embed=embed)

# Additional gambling games
@bot.command(name='coinflip', aliases=['cf'])
async def coinflip(ctx, bet: int, choice: str):
    """Coinflip gambling game"""
    if bot.db.get_setting('gambling_enabled') != 'true':
        await ctx.send(embed=discord.Embed(
            title="🚫 Gambling Disabled",
            description="Gambling is currently disabled by an administrator.",
            color=COLORS['error']
        ))
        return
    
    if bet <= 0:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Bet",
            description="Bet must be greater than 0.",
            color=COLORS['error']
        ))
        return
    
    choice = choice.lower()
    if choice not in ['heads', 'tails', 'h', 't']:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Choice",
            description="Choose either 'heads' or 'tails'.",
            color=COLORS['error']
        ))
        return
    
    user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    
    if user_data['zolar'] < bet:
        await ctx.send(embed=discord.Embed(
            title="❌ Insufficient Funds",
            description=f"You don't have enough Zolar. You have {user_data['zolar']:,} Zolar.",
            color=COLORS['error']
        ))
        return
    
    # Normalize choice
    if choice in ['h', 'heads']:
        user_choice = 'heads'
    else:
        user_choice = 'tails'
    
    # Flip coin
    result = random.choice(['heads', 'tails'])
    won = result == user_choice
    
    # Update balance
    if won:
        winnings = bet * 2
        new_balance = user_data['zolar'] + bet  # Return bet + winnings
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet,
                          total_won=user_data['total_won'] + winnings)
    else:
        new_balance = user_data['zolar'] - bet
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet)
    
    embed = discord.Embed(
        title="🪙 Coinflip",
        color=COLORS['success'] if won else COLORS['error']
    )
    
    embed.add_field(name="Your Choice", value=user_choice.title(), inline=True)
    embed.add_field(name="Result", value=result.title(), inline=True)
    embed.add_field(name="Outcome", value="🎉 You won!" if won else "😞 You lost!", inline=True)
    
    if won:
        embed.add_field(name="Winnings", value=f"+{bet:,} Zolar", inline=True)
    else:
        embed.add_field(name="Lost", value=f"-{bet:,} Zolar", inline=True)
    
    embed.add_field(name="New Balance", value=f"{new_balance:,} Zolar", inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='dice')
async def dice(ctx, bet: int, guess: int):
    """Dice gambling game"""
    if bot.db.get_setting('gambling_enabled') != 'true':
        await ctx.send(embed=discord.Embed(
            title="🚫 Gambling Disabled",
            description="Gambling is currently disabled by an administrator.",
            color=COLORS['error']
        ))
        return
    
    if bet <= 0:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Bet",
            description="Bet must be greater than 0.",
            color=COLORS['error']
        ))
        return
    
    if guess < 1 or guess > 6:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Guess",
            description="Guess must be between 1 and 6.",
            color=COLORS['error']
        ))
        return
    
    user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    
    if user_data['zolar'] < bet:
        await ctx.send(embed=discord.Embed(
            title="❌ Insufficient Funds",
            description=f"You don't have enough Zolar. You have {user_data['zolar']:,} Zolar.",
            color=COLORS['error']
        ))
        return
    
    # Roll dice
    result = random.randint(1, 6)
    won = result == guess
    
    # Update balance
    if won:
        winnings = bet * 6  # 6x multiplier for guessing exact number
        new_balance = user_data['zolar'] + winnings - bet
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet,
                          total_won=user_data['total_won'] + winnings)
    else:
        new_balance = user_data['zolar'] - bet
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet)
    
    dice_emojis = ['⚀', '⚁', '⚂', '⚃', '⚄', '⚅']
    
    embed = discord.Embed(
        title="🎲 Dice Roll",
        color=COLORS['success'] if won else COLORS['error']
    )
    
    embed.add_field(name="Your Guess", value=f"{guess} {dice_emojis[guess-1]}", inline=True)
    embed.add_field(name="Result", value=f"{result} {dice_emojis[result-1]}", inline=True)
    embed.add_field(name="Outcome", value="🎉 You won!" if won else "😞 You lost!", inline=True)
    
    if won:
        embed.add_field(name="Winnings", value=f"+{winnings:,} Zolar", inline=True)
    else:
        embed.add_field(name="Lost", value=f"-{bet:,} Zolar", inline=True)
    
    embed.add_field(name="New Balance", value=f"{new_balance:,} Zolar", inline=True)
    
    await ctx.send(embed=embed)

@bot.command(name='slots')
async def slots(ctx, bet: int):
    """Slot machine gambling game"""
    if bot.db.get_setting('gambling_enabled') != 'true':
        await ctx.send(embed=discord.Embed(
            title="🚫 Gambling Disabled",
            description="Gambling is currently disabled by an administrator.",
            color=COLORS['error']
        ))
        return
    
    if bet <= 0:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Bet",
            description="Bet must be greater than 0.",
            color=COLORS['error']
        ))
        return
    
    user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
    
    if user_data['zolar'] < bet:
        await ctx.send(embed=discord.Embed(
            title="❌ Insufficient Funds",
            description=f"You don't have enough Zolar. You have {user_data['zolar']:,} Zolar.",
            color=COLORS['error']
        ))
        return
    
    # Slot symbols with different probabilities
    symbols = ['🍒', '🍋', '🍊', '🍇', '🔔', '💎', '7️⃣']
    weights = [30, 25, 20, 15, 7, 2, 1]  # Higher weight = more common
    
    # Spin the slots
    result = random.choices(symbols, weights=weights, k=3)
    
    # Calculate winnings
    winnings = 0
    multiplier = 0
    
    if result[0] == result[1] == result[2]:
        # Three of a kind
        if result[0] == '💎':
            multiplier = 50
        elif result[0] == '7️⃣':
            multiplier = 25
        elif result[0] == '🔔':
            multiplier = 10
        elif result[0] == '🍇':
            multiplier = 5
        elif result[0] == '🍊':
            multiplier = 3
        elif result[0] == '🍋':
            multiplier = 2
        elif result[0] == '🍒':
            multiplier = 1.5
    elif result[0] == result[1] or result[1] == result[2] or result[0] == result[2]:
        # Two of a kind (small win)
        multiplier = 0.5
    
    if multiplier > 0:
        winnings = int(bet * multiplier)
        new_balance = user_data['zolar'] + winnings - bet
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet,
                          total_won=user_data['total_won'] + winnings)
    else:
        new_balance = user_data['zolar'] - bet
        bot.db.update_user(ctx.author.id, 
                          zolar=new_balance,
                          total_gambled=user_data['total_gambled'] + bet)
    
    embed = discord.Embed(
        title="🎰 Slot Machine",
        color=COLORS['success'] if winnings > 0 else COLORS['error']
    )
    
    embed.add_field(name="Result", value=f"{''.join(result)}", inline=False)
    
    if winnings > 0:
        embed.add_field(name="Multiplier", value=f"{multiplier}x", inline=True)
        embed.add_field(name="Winnings", value=f"+{winnings:,} Zolar", inline=True)
        embed.add_field(name="Outcome", value="🎉 You won!", inline=True)
    else:
        embed.add_field(name="Outcome", value="😞 You lost!", inline=True)
        embed.add_field(name="Lost", value=f"-{bet:,} Zolar", inline=True)
    
    embed.add_field(name="New Balance", value=f"{new_balance:,} Zolar", inline=True)
    
    await ctx.send(embed=embed)

# Leaderboard command
@bot.command(name='leaderboard', aliases=['lb', 'top'])
async def leaderboard(ctx, category: str = 'zolar'):
    """Show leaderboards"""
    category = category.lower()
    
    if category not in ['zolar', 'xp', 'rank', 'gambled', 'won']:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Category",
            description="Available categories: `zolar`, `xp`, `rank`, `gambled`, `won`",
            color=COLORS['error']
        ))
        return
    
    with sqlite3.connect(bot.db.db_path) as conn:
        cursor = conn.cursor()
        
        if category == 'zolar':
            cursor.execute('SELECT username, zolar FROM users ORDER BY zolar DESC LIMIT 10')
            title = "💰 Top Zolar Holders"
            format_func = lambda x: f"{x:,} Zolar"
        elif category == 'xp':
            cursor.execute('SELECT username, xp FROM users ORDER BY xp DESC LIMIT 10')
            title = "⭐ Top XP Earners"
            format_func = lambda x: f"{x:,} XP"
        elif category == 'rank':
            cursor.execute('SELECT username, rank, xp FROM users ORDER BY rank DESC, xp DESC LIMIT 10')
            title = "👑 Top Ranks"
            format_func = lambda x: f"{RANKS[x[0]]} ({x[1]:,} XP)"
        elif category == 'gambled':
            cursor.execute('SELECT username, total_gambled FROM users ORDER BY total_gambled DESC LIMIT 10')
            title = "🎲 Top Gamblers"
            format_func = lambda x: f"{x:,} Zolar"
        elif category == 'won':
            cursor.execute('SELECT username, total_won FROM users ORDER BY total_won DESC LIMIT 10')
            title = "🏆 Top Winners"
            format_func = lambda x: f"{x:,} Zolar"
        
        results = cursor.fetchall()
    
    if not results:
        await ctx.send(embed=discord.Embed(
            title="📊 Leaderboard",
            description="No data available yet!",
            color=COLORS['info']
        ))
        return
    
    embed = discord.Embed(
        title=title,
        color=COLORS['gold']
    )
    
    medals = ['🥇', '🥈', '🥉'] + ['🏅'] * 7
    
    leaderboard_text = ""
    for i, result in enumerate(results):
        if category == 'rank':
            username, rank, xp = result
            value = format_func((rank, xp))
        else:
            username, value = result
            value = format_func(value)
        
        leaderboard_text += f"{medals[i]} **{username}** - {value}\n"
    
    embed.description = leaderboard_text
    embed.set_footer(text=f"Category: {category.title()}")
    
    await ctx.send(embed=embed)

# Redeem codes system
@bot.command(name='redeem')
async def redeem(ctx, code: str):
    """Redeem a special code"""
    with sqlite3.connect(bot.db.db_path) as conn:
        cursor = conn.cursor()
        
        # Check if codes table exists, create if not
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS redeem_codes (
                code TEXT PRIMARY KEY,
                reward_type TEXT,
                reward_amount INTEGER,
                uses_left INTEGER,
                created_by INTEGER,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        
        # Check if code exists and has uses left
        cursor.execute('SELECT * FROM redeem_codes WHERE code = ? AND uses_left > 0', (code,))
        code_data = cursor.fetchone()
        
        if not code_data:
            await ctx.send(embed=discord.Embed(
                title="❌ Invalid Code",
                description="This code is either invalid or has been fully used.",
                color=COLORS['error']
            ))
            return
        
        # Check if user already redeemed this code
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS code_redemptions (
                user_id INTEGER,
                code TEXT,
                redeemed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (user_id, code)
            )
        ''')
        
        cursor.execute('SELECT * FROM code_redemptions WHERE user_id = ? AND code = ?', 
                      (ctx.author.id, code))
        
        if cursor.fetchone():
            await ctx.send(embed=discord.Embed(
                title="❌ Already Redeemed",
                description="You have already redeemed this code!",
                color=COLORS['error']
            ))
            return
        
        # Redeem the code
        _, reward_type, reward_amount, uses_left, _, _ = code_data
        
        user_data = bot.db.get_user(ctx.author.id, ctx.author.name)
        
        if reward_type == 'zolar':
            new_balance = user_data['zolar'] + reward_amount
            bot.db.update_user(ctx.author.id, zolar=new_balance)
            reward_text = f"{reward_amount:,} Zolar"
        elif reward_type == 'xp':
            new_xp = user_data['xp'] + reward_amount
            new_rank = bot.calculate_rank(new_xp)
            bot.db.update_user(ctx.author.id, xp=new_xp, rank=new_rank)
            reward_text = f"{reward_amount:,} XP"
        
        # Record redemption
        cursor.execute('INSERT INTO code_redemptions (user_id, code) VALUES (?, ?)', 
                      (ctx.author.id, code))
        
        # Decrease uses left
        cursor.execute('UPDATE redeem_codes SET uses_left = uses_left - 1 WHERE code = ?', (code,))
        
        conn.commit()
        
        embed = discord.Embed(
            title="🎁 Code Redeemed!",
            description=f"You received **{reward_text}**!",
            color=COLORS['success']
        )
        
        await ctx.send(embed=embed)

# Admin command to create codes
@bot.command(name='createcode')
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def create_code(ctx, code: str, reward_type: str, reward_amount: int, uses: int = 1):
    """Create a redeemable code (Admin only)"""
    if reward_type.lower() not in ['zolar', 'xp']:
        await ctx.send(embed=discord.Embed(
            title="❌ Invalid Reward Type",
            description="Reward type must be 'zolar' or 'xp'.",
            color=COLORS['error']
        ))
        return
    
    with sqlite3.connect(bot.db.db_path) as conn:
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT INTO redeem_codes (code, reward_type, reward_amount, uses_left, created_by)
                VALUES (?, ?, ?, ?, ?)
            ''', (code, reward_type.lower(), reward_amount, uses, ctx.author.id))
            conn.commit()
            
            embed = discord.Embed(
                title="✅ Code Created",
                description=f"Code `{code}` has been created!",
                color=COLORS['success']
            )
            embed.add_field(name="Reward", value=f"{reward_amount:,} {reward_type.title()}", inline=True)
            embed.add_field(name="Uses", value=f"{uses:,}", inline=True)
            
            await ctx.send(embed=embed)
        
        except sqlite3.IntegrityError:
            await ctx.send(embed=discord.Embed(
                title="❌ Code Already Exists",
                description="A code with this name already exists!",
                color=COLORS['error']
            ))

# Server stats command
@bot.command(name='serverstats')
@commands.check(lambda ctx: bot.is_admin(ctx.author.id))
async def server_stats(ctx):
    """Show server statistics (Admin only)"""
    with sqlite3.connect(bot.db.db_path) as conn:
        cursor = conn.cursor()
        
        # Get user count
        cursor.execute('SELECT COUNT(*) FROM users')
        user_count = cursor.fetchone()[0]
        
        # Get total Zolar in circulation
        cursor.execute('SELECT SUM(zolar) FROM users')
        total_zolar = cursor.fetchone()[0] or 0
        
        # Get total XP earned
        cursor.execute('SELECT SUM(xp) FROM users')
        total_xp = cursor.fetchone()[0] or 0
        
        # Get gambling stats
        cursor.execute('SELECT SUM(total_gambled), SUM(total_won) FROM users')
        gambling_stats = cursor.fetchone()
        total_gambled = gambling_stats[0] or 0
        total_won = gambling_stats[1] or 0
        
        # Get rank distribution
        cursor.execute('SELECT rank, COUNT(*) FROM users GROUP BY rank ORDER BY rank')
        rank_dist = cursor.fetchall()
        
        # Get active codes
        cursor.execute('SELECT COUNT(*) FROM redeem_codes WHERE uses_left > 0')
        active_codes = cursor.fetchone()[0] or 0
    
    embed = discord.Embed(
        title="📊 Server Statistics",
        color=COLORS['info']
    )
    
    embed.add_field(name="👥 Total Users", value=f"{user_count:,}", inline=True)
    embed.add_field(name="💰 Total Zolar", value=f"{total_zolar:,}", inline=True)
    embed.add_field(name="⭐ Total XP", value=f"{total_xp:,}", inline=True)
    
    embed.add_field(name="🎲 Total Gambled", value=f"{total_gambled:,}", inline=True)
    embed.add_field(name="🏆 Total Won", value=f"{total_won:,}", inline=True)
    embed.add_field(name="🎁 Active Codes", value=f"{active_codes:,}", inline=True)
    
    # Rank distribution
    rank_text = ""
    for rank, count in rank_dist:
        rank_text += f"{RANKS[rank]}: {count:,}\n"
    
    if rank_text:
        embed.add_field(name="👑 Rank Distribution", value=rank_text, inline=False)
    
    # Gambling status
    gambling_status = "🟢 Enabled" if bot.db.get_setting('gambling_enabled') == 'true' else "🔴 Disabled"
    embed.add_field(name="🎰 Gambling Status", value=gambling_status, inline=True)
    
    await ctx.send(embed=embed)

# Error handling
@bot.event
async def on_command_error(ctx, error):
    """Handle command errors"""
    if isinstance(error, commands.CommandNotFound):
        return  # Ignore unknown commands
    
    elif isinstance(error, commands.MissingRequiredArgument):
        embed = discord.Embed(
            title="❌ Missing Argument",
            description=f"Missing required argument: `{error.param.name}`",
            color=COLORS['error']
        )
        await ctx.send(embed=embed)
    
    elif isinstance(error, commands.BadArgument):
        embed = discord.Embed(
            title="❌ Invalid Argument",
            description="One or more arguments are invalid. Please check your command.",
            color=COLORS['error']
        )
        await ctx.send(embed=embed)
    
    elif isinstance(error, commands.CheckFailure):
        embed = discord.Embed(
            title="❌ Permission Denied",
            description="You don't have permission to use this command.",
            color=COLORS['error']
        )
        await ctx.send(embed=embed)
    
    else:
        logger.error(f"Unexpected error: {error}")
        embed = discord.Embed(
            title="❌ An Error Occurred",
            description="Something went wrong while processing your command. Please try again.",
            color=COLORS['error']
        )
        await ctx.send(embed=embed)

# Main execution
if __name__ == "__main__":
    # Bot token - Replace with your bot token
    BOT_TOKEN = "YOUR_BOT_TOKEN_HERE"
    
    print("🏰 Starting Empire Bot...")
    print("📁 Initializing database...")
    
    try:
        bot.run(BOT_TOKEN)
    except Exception as e:
        logger.error(f"Failed to start bot: {e}")
        print("❌ Bot failed to start. Please check your token and try again.")
