#!/usr/bin/env python3
"""
Fantasy RPG Character Management System

A comprehensive demonstration of modern Python features including:
- Pydantic models with validation
- Async/await programming
- Enum usage
- Database operations with DuckDB
- Rich console output
- Error handling and logging
- Type hints and generics
- Context managers
- Decorators
"""

import asyncio
import logging
from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager
from datetime import datetime
from enum import Enum, StrEnum, auto
from random import choice, randint, uniform

import duckdb
from faker import Faker
from pydantic import BaseModel, Field, PrivateAttr, computed_field, field_validator
from uuid_extensions import uuid7str

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

fake = Faker()


class CharacterClass(StrEnum):
    """Available character classes in our RPG."""

    WARRIOR = "warrior"
    MAGE = "mage"
    ROGUE = "rogue"
    CLERIC = "cleric"
    RANGER = "ranger"
    PALADIN = "paladin"
    BARBARIAN = "barbarian"
    BARD = "bard"


class Race(StrEnum):
    """Available character races."""

    HUMAN = "human"
    ELF = "elf"
    DWARF = "dwarf"
    HALFLING = "halfling"
    ORC = "orc"
    GNOME = "gnome"
    TIEFLING = "tiefling"
    DRAGONBORN = "dragonborn"


class QuestStatus(Enum):
    """Status of a quest."""

    AVAILABLE = auto()
    IN_PROGRESS = auto()
    COMPLETED = auto()
    FAILED = auto()


class Stats(BaseModel):
    """Character statistics."""

    strength: int = Field(..., ge=1, le=20, description="Physical power")
    dexterity: int = Field(..., ge=1, le=20, description="Agility and reflexes")
    intelligence: int = Field(..., ge=1, le=20, description="Mental acuity")
    wisdom: int = Field(..., ge=1, le=20, description="Perception and insight")
    constitution: int = Field(..., ge=1, le=20, description="Health and stamina")
    charisma: int = Field(..., ge=1, le=20, description="Force of personality")

    @computed_field
    @property
    def total(self) -> int:
        """Total of all stats."""
        return (
            self.strength
            + self.dexterity
            + self.intelligence
            + self.wisdom
            + self.constitution
            + self.charisma
        )

    @computed_field
    @property
    def modifier(self) -> dict[str, int]:
        """Calculate D&D style modifiers for each stat."""
        return {
            "strength": (self.strength - 10) // 2,
            "dexterity": (self.dexterity - 10) // 2,
            "intelligence": (self.intelligence - 10) // 2,
            "wisdom": (self.wisdom - 10) // 2,
            "constitution": (self.constitution - 10) // 2,
            "charisma": (self.charisma - 10) // 2,
        }


class Equipment(BaseModel):
    """Character equipment."""

    name: str
    item_type: str
    rarity: str = Field(..., pattern=r"^(common|uncommon|rare|epic|legendary)$")
    value: int = Field(..., ge=0)
    description: str | None = None

    @field_validator("name")
    @classmethod
    def name_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError("Equipment name cannot be empty")
        return v.title()


class Quest(BaseModel):
    """A quest that characters can undertake."""

    id: str = Field(default_factory=uuid7str)
    title: str
    description: str
    reward_gold: int = Field(..., ge=0)
    reward_xp: int = Field(..., ge=0)
    status: QuestStatus = QuestStatus.AVAILABLE
    difficulty: int = Field(..., ge=1, le=10)
    created_at: datetime = Field(default_factory=datetime.now)


class Character(BaseModel):
    """A fantasy RPG character with comprehensive attributes."""

    name: str = Field(..., min_length=2, max_length=50)
    character_class: CharacterClass
    race: Race
    level: int = Field(default=1, ge=1, le=100)
    experience: int = Field(default=0, ge=0)
    gold: int = Field(default=100, ge=0)
    stats: Stats
    equipment: list[Equipment] = Field(default_factory=list)
    active_quests: list[str] = Field(default_factory=list)  # Quest IDs
    completed_quests: list[str] = Field(default_factory=list)  # Quest IDs
    created_at: datetime = Field(default_factory=datetime.now)
    _id: str = PrivateAttr(default_factory=uuid7str)

    @computed_field
    @property
    def id(self) -> str:
        """Returns the unique ID of the character."""
        return self._id

    @computed_field
    @property
    def hit_points(self) -> int:
        """Calculate hit points based on level and constitution."""
        base_hp = {
            CharacterClass.WARRIOR: 12,
            CharacterClass.PALADIN: 12,
            CharacterClass.BARBARIAN: 14,
            CharacterClass.RANGER: 10,
            CharacterClass.ROGUE: 8,
            CharacterClass.BARD: 8,
            CharacterClass.CLERIC: 8,
            CharacterClass.MAGE: 6,
        }[self.character_class]

        constitution_bonus = self.stats.modifier["constitution"]
        return (
            base_hp + (self.level - 1) * (6 + constitution_bonus) + constitution_bonus
        )

    @computed_field
    @property
    def armor_class(self) -> int:
        """Calculate armor class."""
        base_ac = 10 + self.stats.modifier["dexterity"]
        # Add armor bonuses from equipment
        armor_bonus = sum(
            2 for item in self.equipment if item.item_type.lower() == "armor"
        )
        return base_ac + armor_bonus

    @computed_field
    @property
    def total_equipment_value(self) -> int:
        """Total value of all equipment."""
        return sum(item.value for item in self.equipment)

    @field_validator("name")
    @classmethod
    def name_must_be_valid(cls, v):
        if not v.strip():
            raise ValueError("Character name cannot be empty")
        if any(char.isdigit() for char in v):
            raise ValueError("Character name cannot contain numbers")
        return v.title()

    def add_experience(self, xp: int) -> bool:
        """Add experience and level up if necessary."""
        self.experience += xp
        old_level = self.level

        # Simple leveling formula: 1000 XP per level
        new_level = min(self.experience // 1000 + 1, 100)

        if new_level > old_level:
            self.level = new_level
            logger.info(f"{self.name} leveled up to level {self.level}!")
            return True
        return False

    def add_equipment(self, equipment: Equipment) -> None:
        """Add equipment to character."""
        self.equipment.append(equipment)
        logger.info(f"{self.name} acquired {equipment.name}")

    def start_quest(self, quest_id: str) -> None:
        """Start a new quest."""
        if quest_id not in self.active_quests:
            self.active_quests.append(quest_id)
            logger.info(f"{self.name} started a new quest")

    def complete_quest(self, quest_id: str, quest: Quest) -> None:
        """Complete a quest and gain rewards."""
        if quest_id in self.active_quests:
            self.active_quests.remove(quest_id)
            self.completed_quests.append(quest_id)
            self.gold += quest.reward_gold
            leveled_up = self.add_experience(quest.reward_xp)

            logger.info(
                f"{self.name} completed quest '{quest.title}' and gained "
                f"{quest.reward_gold} gold and {quest.reward_xp} XP"
            )
            if leveled_up:
                logger.info(f"🎉 {self.name} leveled up!")


class Repository[T: BaseModel]:
    """Generic repository for database operations."""

    def __init__(self, db_path: str, table_name: str, model_class: type[T]):
        self.db_path = db_path
        self.table_name = table_name
        self.model_class = model_class

    @asynccontextmanager
    async def get_connection(self) -> AsyncGenerator[duckdb.DuckDBPyConnection]:
        """Get a database connection with automatic cleanup."""
        conn = duckdb.connect(self.db_path)
        try:
            yield conn
        finally:
            conn.close()

    async def create_table(self) -> None:
        """Create the table if it doesn't exist."""
        async with self.get_connection() as conn:
            conn.execute(f"""
                CREATE TABLE IF NOT EXISTS {self.table_name} (
                    id VARCHAR PRIMARY KEY,
                    data JSON,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)

    async def save(self, item: T) -> None:
        """Save an item to the database."""
        async with self.get_connection() as conn:
            conn.execute(
                f"INSERT OR REPLACE INTO {self.table_name} (id, data) VALUES (?, ?)",
                [item.id, item.model_dump_json()],
            )

    async def find_by_id(self, item_id: str) -> T | None:
        """Find an item by ID."""
        async with self.get_connection() as conn:
            result = conn.execute(
                f"SELECT data FROM {self.table_name} WHERE id = ?", [item_id]
            ).fetchone()

            if result:
                return self.model_class.model_validate_json(result[0])
            return None

    async def find_all(self) -> list[T]:
        """Find all items."""
        async with self.get_connection() as conn:
            results = conn.execute(f"SELECT data FROM {self.table_name}").fetchall()
            return [self.model_class.model_validate_json(row[0]) for row in results]

    async def delete(self, item_id: str) -> bool:
        """Delete an item by ID."""
        async with self.get_connection() as conn:
            cursor = conn.execute(
                f"DELETE FROM {self.table_name} WHERE id = ?", [item_id]
            )
            return cursor.rowcount > 0


class GameEngine:
    """Main game engine that orchestrates all operations."""

    def __init__(self, db_path: str = "rpg_game.db"):
        self.character_repo = Repository(db_path, "characters", Character)
        self.quest_repo = Repository(db_path, "quests", Quest)
        self.equipment_generators = {
            "weapon": self._generate_weapon,
            "armor": self._generate_armor,
            "accessory": self._generate_accessory,
        }

    async def initialize(self) -> None:
        """Initialize the game engine and database."""
        await self.character_repo.create_table()
        await self.quest_repo.create_table()
        logger.info("Game engine initialized")

    def _generate_stats(self) -> Stats:
        """Generate random character stats."""
        return Stats(
            strength=randint(8, 18),
            dexterity=randint(8, 18),
            intelligence=randint(8, 18),
            wisdom=randint(8, 18),
            constitution=randint(8, 18),
            charisma=randint(8, 18),
        )

    def _generate_weapon(self) -> Equipment:
        """Generate a random weapon."""
        weapons = [
            "Sword",
            "Axe",
            "Bow",
            "Staff",
            "Dagger",
            "Mace",
            "Spear",
            "Crossbow",
        ]
        rarities = ["common", "uncommon", "rare", "epic", "legendary"]
        rarity = choice(rarities)

        base_value = {
            "common": 50,
            "uncommon": 150,
            "rare": 400,
            "epic": 1000,
            "legendary": 2500,
        }

        return Equipment(
            name=f"{fake.word().title()} {choice(weapons)}",
            item_type="weapon",
            rarity=rarity,
            value=base_value[rarity] + randint(-20, 100),
            description=f"A {rarity} weapon forged by {fake.name()}",
        )

    def _generate_armor(self) -> Equipment:
        """Generate random armor."""
        armors = ["Helmet", "Chestplate", "Boots", "Gloves", "Shield", "Cloak"]
        rarities = ["common", "uncommon", "rare", "epic", "legendary"]
        rarity = choice(rarities)

        base_value = {
            "common": 30,
            "uncommon": 100,
            "rare": 300,
            "epic": 800,
            "legendary": 2000,
        }

        return Equipment(
            name=f"{fake.word().title()} {choice(armors)}",
            item_type="armor",
            rarity=rarity,
            value=base_value[rarity] + randint(-10, 50),
            description=f"A {rarity} piece of armor",
        )

    def _generate_accessory(self) -> Equipment:
        """Generate random accessory."""
        accessories = ["Ring", "Amulet", "Pendant", "Bracelet", "Earrings"]
        rarities = ["uncommon", "rare", "epic", "legendary"]
        rarity = choice(rarities)

        base_value = {"uncommon": 200, "rare": 500, "epic": 1200, "legendary": 3000}

        return Equipment(
            name=f"{fake.word().title()} {choice(accessories)}",
            item_type="accessory",
            rarity=rarity,
            value=base_value[rarity] + randint(0, 200),
            description=f"A magical {rarity} accessory with mysterious powers",
        )

    async def create_random_character(self) -> Character:
        """Create a random character with equipment."""
        character = Character(
            name=fake.name(),
            character_class=choice(list(CharacterClass)),
            race=choice(list(Race)),
            level=randint(1, 10),
            gold=randint(100, 1000),
            stats=self._generate_stats(),
        )

        # Add some random equipment
        for _ in range(randint(1, 4)):
            equipment_type = choice(list(self.equipment_generators.keys()))
            equipment = self.equipment_generators[equipment_type]()
            character.add_equipment(equipment)

        # Calculate experience based on level
        character.experience = (character.level - 1) * 1000 + randint(0, 999)

        await self.character_repo.save(character)
        logger.info(
            f"Created character: {character.name} "
            f"({character.character_class.value} {character.race.value})"
        )
        return character

    async def create_random_quest(self) -> Quest:
        """Create a random quest."""
        quest_titles = [
            "Slay the Dragon",
            "Retrieve the Lost Artifact",
            "Escort the Merchant",
            "Clear the Goblin Cave",
            "Deliver the Message",
            "Find the Missing Person",
            "Collect Rare Herbs",
            "Defeat the Bandit Leader",
        ]

        difficulty = randint(1, 10)

        quest = Quest(
            title=choice(quest_titles),
            description=fake.text(max_nb_chars=200),
            reward_gold=difficulty * randint(50, 200),
            reward_xp=difficulty * randint(100, 300),
            difficulty=difficulty,
        )

        await self.quest_repo.save(quest)
        logger.info(f"Created quest: {quest.title} (Difficulty: {quest.difficulty})")
        return quest

    async def simulate_quest_completion(
        self, character: Character, quest: Quest
    ) -> None:
        """Simulate a character completing a quest."""
        # Simple success chance based on character level vs quest difficulty
        success_chance = min(0.9, max(0.1, character.level / quest.difficulty * 0.5))

        if uniform(0, 1) < success_chance:
            character.complete_quest(quest.id, quest)
            quest.status = QuestStatus.COMPLETED
            await self.character_repo.save(character)
            await self.quest_repo.save(quest)
        else:
            quest.status = QuestStatus.FAILED
            await self.quest_repo.save(quest)
            logger.info(f"{character.name} failed quest '{quest.title}'")

    async def display_character_info(self, character: Character) -> None:
        """Display comprehensive character information."""
        print(f"\n{'=' * 60}")
        print(f"CHARACTER: {character.name}")
        print(f"{'=' * 60}")
        print(f"Race: {character.race.value.title()}")
        print(f"Class: {character.character_class.value.title()}")
        print(f"Level: {character.level} (XP: {character.experience})")
        print(f"Gold: {character.gold}")
        print(f"Hit Points: {character.hit_points}")
        print(f"Armor Class: {character.armor_class}")

        print(f"\nSTATS (Total: {character.stats.total}):")
        stats_dict = character.stats.model_dump(exclude={"total", "modifier"})
        for stat, value in stats_dict.items():
            modifier = character.stats.modifier[stat]
            modifier_str = f"+{modifier}" if modifier >= 0 else str(modifier)
            print(f"  {stat.title()}: {value} ({modifier_str})")

        if character.equipment:
            print(f"\nEQUIPMENT (Total Value: {character.total_equipment_value} gold):")
            for item in character.equipment:
                print(f"  • {item.name} ({item.rarity}) - {item.value} gold")

        print("\nQUESTS:")
        print(f"  Active: {len(character.active_quests)}")
        print(f"  Completed: {len(character.completed_quests)}")
        print(f"\nCreated: {character.created_at.strftime('%Y-%m-%d %H:%M:%S')}")


async def demo_comprehensive_features() -> None:
    """Demonstrate all the features of our RPG system."""
    print("🎮 Starting Fantasy RPG Character Management System Demo!")
    print("=" * 70)

    # Initialize game engine
    engine = GameEngine()
    await engine.initialize()

    # Create multiple characters
    characters = []
    for _ in range(3):
        character = await engine.create_random_character()
        characters.append(character)

    # Create some quests
    quests = []
    for _ in range(5):
        quest = await engine.create_random_quest()
        quests.append(quest)

    # Assign quests to characters and simulate completion
    for character in characters:
        # Each character gets 1-2 quests
        character_quests = choice(quests), choice(quests)
        for quest in character_quests:
            if quest.id not in character.active_quests:
                character.start_quest(quest.id)

                # 70% chance to complete the quest immediately
                if uniform(0, 1) < 0.7:
                    await engine.simulate_quest_completion(character, quest)

        await engine.character_repo.save(character)

    # Display all character information
    for character in characters:
        await engine.display_character_info(character)

    # Show quest summary
    print(f"\n{'=' * 60}")
    print("QUEST SUMMARY")
    print(f"{'=' * 60}")
    for quest in quests:
        status_emoji = {
            QuestStatus.AVAILABLE: "🔷",
            QuestStatus.IN_PROGRESS: "🔶",
            QuestStatus.COMPLETED: "✅",
            QuestStatus.FAILED: "❌",
        }
        print(
            f"{status_emoji[quest.status]} {quest.title} "
            f"(Difficulty: {quest.difficulty})"
        )
        print(f"   Reward: {quest.reward_gold} gold, {quest.reward_xp} XP")

    # Database operations demo
    print(f"\n{'=' * 60}")
    print("DATABASE OPERATIONS")
    print(f"{'=' * 60}")

    all_characters = await engine.character_repo.find_all()
    print(f"Total characters in database: {len(all_characters)}")

    all_quests = await engine.quest_repo.find_all()
    print(f"Total quests in database: {len(all_quests)}")

    # Find specific character
    if characters:
        found_character = await engine.character_repo.find_by_id(characters[0].id)
        if found_character:
            print(f"Found character by ID: {found_character.name}")

    print("\n🎉 Demo completed successfully!")


async def main() -> None:
    """Main application entry point."""
    try:
        await demo_comprehensive_features()
    except Exception as e:
        logger.error(f"An error occurred: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
