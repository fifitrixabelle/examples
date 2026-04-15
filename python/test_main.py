import asyncio
import unittest

from main import (
    Character,
    Equipment,
    GameEngine,
    Quest,
    Stats,
    demo_comprehensive_features,
)


class TestRPGSystem(unittest.TestCase):
    """Test suite for the RPG Character Management System."""

    def setUp(self):
        """Set up test dependencies."""
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)

    def tearDown(self):
        """Clean up after tests."""
        self.loop.close()

    def test_character_creation(self):
        """Test creating a character."""

        async def run_test():
            game_engine = GameEngine()
            await game_engine.initialize()

            character = await game_engine.create_random_character()

            self.assertIsInstance(character, Character)
            self.assertIsInstance(character.stats, Stats)
            self.assertGreaterEqual(character.gold, 100)

        self.loop.run_until_complete(run_test())

    def test_quest_creation(self):
        """Test creating a quest."""

        async def run_test():
            game_engine = GameEngine()
            await game_engine.initialize()

            quest = await game_engine.create_random_quest()

            self.assertIsInstance(quest, Quest)
            self.assertGreaterEqual(quest.reward_gold, 0)
            self.assertGreaterEqual(quest.reward_xp, 0)

        self.loop.run_until_complete(run_test())

    def test_equipment(self):
        """Test equipment setup and values."""
        equipment = Equipment(
            name="Legendary Sword", item_type="weapon", rarity="legendary", value=3000
        )

        self.assertEqual(equipment.name, "Legendary Sword")
        self.assertEqual(equipment.value, 3000)

    def test_full_demo_run(self):
        """Ensure the full demo runs without error."""

        async def run_test():
            try:
                await demo_comprehensive_features()
            except Exception as e:
                self.fail(f"Demo failed with exception {e}")

        self.loop.run_until_complete(run_test())

    def test_character_model_validations(self):
        """Test Character model validations using Pydantic."""
        from pydantic import ValidationError

        from main import CharacterClass, Race

        with self.assertRaises(ValidationError):
            # Empty name should raise
            Character(
                name="",
                character_class=CharacterClass.MAGE,
                race=Race.ELF,
                stats=Stats(
                    strength=10,
                    dexterity=10,
                    intelligence=10,
                    wisdom=10,
                    constitution=10,
                    charisma=10,
                ),
            )

    def test_stat_total_computation(self):
        """Test computation of total and modifiers in stats."""
        stats = Stats(
            strength=16,
            dexterity=14,
            intelligence=12,
            wisdom=10,
            constitution=8,
            charisma=6,
        )

        self.assertEqual(stats.total, 66)
        self.assertEqual(stats.modifier["strength"], 3)
        self.assertEqual(stats.modifier["constitution"], -1)

    def test_repository_functions(self):
        """Test repository save and retrieve functions."""

        async def run_test():
            game_engine = GameEngine()
            await game_engine.initialize()

            character = await game_engine.create_random_character()
            retrieved_character = await game_engine.character_repo.find_by_id(
                character.id
            )

            # Test that we found a character with the same name
            # (since ID regeneration is expected)
            self.assertIsNotNone(retrieved_character)
            self.assertEqual(character.name, retrieved_character.name)
            self.assertEqual(
                character.character_class, retrieved_character.character_class
            )

        self.loop.run_until_complete(run_test())


if __name__ == "__main__":
    unittest.main()
