#!/usr/bin/env python3
"""
RPG CLI - Interactive Command Line Interface for the Fantasy RPG System

Provides commands for creating characters, managing quests, and playing
the game in a tabletop-style interactive experience.
"""

import asyncio
import os
import sys

from main import GameEngine, QuestStatus


class RPGCommandHandler:
    """Handles all RPG CLI commands."""

    def __init__(self, db_path: str = "rpg_game.db"):
        self.engine = GameEngine(db_path)

    async def interactive(self) -> None:
        """Start an interactive RPG session."""
        await self.engine.initialize()

        print("🏰 " + "=" * 60)
        print("   WELCOME TO THE FANTASY RPG COMMAND CENTER!")
        print("=" * 64)
        print("\n📜 Available commands:")
        print("  • just create-character    - Create a new random character")
        print("  • just create-quest        - Create a new random quest")
        print("  • just list-characters     - Show all characters")
        print("  • just list-quests         - Show all quests")
        print("  • just show-character NAME - Show character details")
        print("  • just show-quest TITLE   - Show quest details")
        print("  • just assign-quest NAME TITLE - Assign quest to character")
        print("  • just complete-quest NAME TITLE - Complete quest")
        print("  • just game-stats          - Show game statistics")
        print("  • just reset-game          - Reset all data")
        print("\n🎲 Happy adventuring!\n")

    async def create_character(self) -> None:
        """Create a new random character."""
        await self.engine.initialize()
        character = await self.engine.create_random_character()

        print("\n🧙 CHARACTER CREATED!")
        await self.engine.display_character_info(character)

    async def create_quest(self) -> None:
        """Create a new random quest."""
        await self.engine.initialize()
        quest = await self.engine.create_random_quest()

        print("\n📋 QUEST CREATED!")
        print(f"\n{'=' * 50}")
        print(f"QUEST: {quest.title}")
        print(f"{'=' * 50}")
        print(f"Description: {quest.description}")
        print(f"Difficulty: {quest.difficulty}/10")
        print(f"Reward: {quest.reward_gold} gold, {quest.reward_xp} XP")
        print(f"Status: {quest.status.name}")
        print(f"Created: {quest.created_at.strftime('%Y-%m-%d %H:%M:%S')}")

    async def list_characters(self) -> None:
        """List all characters."""
        await self.engine.initialize()
        characters = await self.engine.character_repo.find_all()

        if not characters:
            print("\n📝 No characters found. Create one with 'just create-character'")
            return

        print(f"\n👥 CHARACTERS ({len(characters)} total)")
        print("=" * 60)

        for char in characters:
            status = "⚡" if char.active_quests else "💤"
            print(
                f"{status} {char.name} - Lvl {char.level} {char.character_class.value.title()} "
                f"{char.race.value.title()} ({char.gold} gold)"
            )

    async def list_quests(self) -> None:
        """List all quests."""
        await self.engine.initialize()
        quests = await self.engine.quest_repo.find_all()

        if not quests:
            print("\n📋 No quests found. Create one with 'just create-quest'")
            return

        print(f"\n📋 QUESTS ({len(quests)} total)")
        print("=" * 60)

        status_emoji = {
            QuestStatus.AVAILABLE: "🔷",
            QuestStatus.IN_PROGRESS: "🔶",
            QuestStatus.COMPLETED: "✅",
            QuestStatus.FAILED: "❌",
        }

        for quest in quests:
            emoji = status_emoji[quest.status]
            print(
                f"{emoji} {quest.title} (Difficulty: {quest.difficulty}) - "
                f"{quest.reward_gold}g, {quest.reward_xp}xp"
            )

    async def show_character(self, name: str) -> None:
        """Show detailed character information."""
        await self.engine.initialize()
        characters = await self.engine.character_repo.find_all()

        character = next(
            (c for c in characters if c.name.lower() == name.lower()), None
        )
        if not character:
            print(f"\n❌ Character '{name}' not found.")
            print("Available characters:")
            for c in characters:
                print(f"  • {c.name}")
            return

        await self.engine.display_character_info(character)

    async def show_quest(self, title: str) -> None:
        """Show detailed quest information."""
        await self.engine.initialize()
        quests = await self.engine.quest_repo.find_all()

        quest = next((q for q in quests if q.title.lower() == title.lower()), None)
        if not quest:
            print(f"\n❌ Quest '{title}' not found.")
            print("Available quests:")
            for q in quests:
                print(f"  • {q.title}")
            return

        status_emoji = {
            QuestStatus.AVAILABLE: "🔷",
            QuestStatus.IN_PROGRESS: "🔶",
            QuestStatus.COMPLETED: "✅",
            QuestStatus.FAILED: "❌",
        }

        print(f"\n{'=' * 50}")
        print(f"QUEST: {quest.title}")
        print(f"{'=' * 50}")
        print(f"Status: {status_emoji[quest.status]} {quest.status.name}")
        print(f"Description: {quest.description}")
        print(f"Difficulty: {quest.difficulty}/10")
        print(f"Reward: {quest.reward_gold} gold, {quest.reward_xp} XP")
        print(f"Created: {quest.created_at.strftime('%Y-%m-%d %H:%M:%S')}")

    async def assign_quest(self, character_name: str, quest_title: str) -> None:
        """Assign a quest to a character."""
        await self.engine.initialize()

        # Find character
        characters = await self.engine.character_repo.find_all()
        character = next(
            (c for c in characters if c.name.lower() == character_name.lower()), None
        )
        if not character:
            print(f"\n❌ Character '{character_name}' not found.")
            return

        # Find quest
        quests = await self.engine.quest_repo.find_all()
        quest = next(
            (q for q in quests if q.title.lower() == quest_title.lower()), None
        )
        if not quest:
            print(f"\n❌ Quest '{quest_title}' not found.")
            return

        # Check if quest is available
        if quest.status != QuestStatus.AVAILABLE:
            print(
                f"\n❌ Quest '{quest_title}' is not available (Status: {quest.status.name})."
            )
            return

        # Check if character already has this quest
        if quest.id in character.active_quests:
            print(f"\n⚠️ {character.name} already has this quest assigned.")
            return

        # Assign quest
        character.start_quest(quest.id)
        quest.status = QuestStatus.IN_PROGRESS

        await self.engine.character_repo.save(character)
        await self.engine.quest_repo.save(quest)

        print(f"\n✅ Quest '{quest.title}' assigned to {character.name}!")
        print(f"   Reward: {quest.reward_gold} gold, {quest.reward_xp} XP")

    async def complete_quest(self, character_name: str, quest_title: str) -> None:
        """Complete a quest for a character."""
        await self.engine.initialize()

        # Find character
        characters = await self.engine.character_repo.find_all()
        character = next(
            (c for c in characters if c.name.lower() == character_name.lower()), None
        )
        if not character:
            print(f"\n❌ Character '{character_name}' not found.")
            return

        # Find quest
        quests = await self.engine.quest_repo.find_all()
        quest = next(
            (q for q in quests if q.title.lower() == quest_title.lower()), None
        )
        if not quest:
            print(f"\n❌ Quest '{quest_title}' not found.")
            return

        # Check if character has this quest
        if quest.id not in character.active_quests:
            print(f"\n❌ {character.name} doesn't have this quest assigned.")
            return

        # Complete quest
        old_level = character.level
        character.complete_quest(quest.id, quest)
        quest.status = QuestStatus.COMPLETED

        await self.engine.character_repo.save(character)
        await self.engine.quest_repo.save(quest)

        print(f"\n🎉 Quest '{quest.title}' completed by {character.name}!")
        print(f"   Gained: {quest.reward_gold} gold, {quest.reward_xp} XP")
        print(f"   New totals: {character.gold} gold, {character.experience} XP")

        if character.level > old_level:
            print(f"   🆙 LEVEL UP! {character.name} is now level {character.level}!")

    async def game_stats(self) -> None:
        """Show game statistics."""
        await self.engine.initialize()

        characters = await self.engine.character_repo.find_all()
        quests = await self.engine.quest_repo.find_all()

        completed_quests = [q for q in quests if q.status == QuestStatus.COMPLETED]
        active_quests = [q for q in quests if q.status == QuestStatus.IN_PROGRESS]
        available_quests = [q for q in quests if q.status == QuestStatus.AVAILABLE]
        failed_quests = [q for q in quests if q.status == QuestStatus.FAILED]

        total_gold = sum(c.gold for c in characters)
        avg_level = (
            sum(c.level for c in characters) / len(characters) if characters else 0
        )

        print("\n📊 GAME STATISTICS")
        print("=" * 50)
        print(f"Characters: {len(characters)}")
        print(f"Total Quests: {len(quests)}")
        print(f"  • Available: {len(available_quests)}")
        print(f"  • In Progress: {len(active_quests)}")
        print(f"  • Completed: {len(completed_quests)}")
        print(f"  • Failed: {len(failed_quests)}")
        print("\nEconomy:")
        print(f"  • Total Gold: {total_gold}")
        print(f"  • Average Level: {avg_level:.1f}")

        if characters:
            highest_level = max(characters, key=lambda c: c.level)
            richest = max(characters, key=lambda c: c.gold)
            print("\nTop Performers:")
            print(
                f"  • Highest Level: {highest_level.name} (Level {highest_level.level})"
            )
            print(f"  • Richest: {richest.name} ({richest.gold} gold)")

    async def reset_game(self) -> None:
        """Reset all game data."""
        db_file = "rpg_game.db"
        if os.path.exists(db_file):
            os.remove(db_file)
            print("\n🗑️ Game data reset! All characters and quests have been deleted.")
        else:
            print("\n💭 No game data found to reset.")


async def main() -> None:
    """Main CLI entry point."""
    if len(sys.argv) < 2:
        print("Usage: python rpg_cli.py <command> [args...]")
        return

    command = sys.argv[1]
    handler = RPGCommandHandler()

    try:
        if command == "interactive":
            await handler.interactive()
        elif command == "create-character":
            await handler.create_character()
        elif command == "create-quest":
            await handler.create_quest()
        elif command == "list-characters":
            await handler.list_characters()
        elif command == "list-quests":
            await handler.list_quests()
        elif command == "show-character":
            if len(sys.argv) < 3:
                print("Usage: python rpg_cli.py show-character <name>")
                return
            await handler.show_character(sys.argv[2])
        elif command == "show-quest":
            if len(sys.argv) < 3:
                print("Usage: python rpg_cli.py show-quest <title>")
                return
            await handler.show_quest(sys.argv[2])
        elif command == "assign-quest":
            if len(sys.argv) < 4:
                print(
                    "Usage: python rpg_cli.py assign-quest <character_name> <quest_title>"
                )
                return
            await handler.assign_quest(sys.argv[2], sys.argv[3])
        elif command == "complete-quest":
            if len(sys.argv) < 4:
                print(
                    "Usage: python rpg_cli.py complete-quest <character_name> <quest_title>"
                )
                return
            await handler.complete_quest(sys.argv[2], sys.argv[3])
        elif command == "game-stats":
            await handler.game_stats()
        elif command == "reset":
            await handler.reset_game()
        else:
            print(f"❌ Unknown command: {command}")
            print(
                "Available commands: interactive, create-character, create-quest, list-characters, list-quests, show-character, show-quest, assign-quest, complete-quest, game-stats, reset"
            )

    except Exception as e:
        print(f"❌ Error: {e}")
        raise


if __name__ == "__main__":
    asyncio.run(main())
