import json
import os
from typing import List, Dict, Optional

class CommandManager:
    """
    Třída pro správu hlasových povelů.
    Zajišťuje načítání, ukládání, přidávání a mazání povelů v JSON souboru.
    """
    def __init__(self, filepath: str = 'commands.json'):
        """
        Inicializuje CommandManager.

        Args:
            filepath (str): Cesta k JSON souboru s povely.
        """
        self.filepath = filepath
        self.commands = self.load_commands()

    def load_commands(self) -> List[Dict[str, str]]:
        """
        Načte povely z JSON souboru.
        Pokud soubor neexistuje, vrátí prázdný seznam.
        """
        if not os.path.exists(self.filepath):
            return []
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            # V případě chyby (např. prázdný soubor) vrátíme prázdný seznam
            return []

    def save_commands(self) -> None:
        """
        Uloží aktuální seznam povelů do JSON souboru.
        """
        with open(self.filepath, 'w', encoding='utf-8') as f:
            # indent=4 zajistí hezké formátování souboru
            json.dump(self.commands, f, indent=4, ensure_ascii=False)

    def add_command(self, name: str, shortcut: str, recording_path: str) -> bool:
        """
        Přidá nový povel do seznamu.

        Args:
            name (str): Unikátní název povelu.
            shortcut (str): Klávesová zkratka.
            recording_path (str): Cesta k WAV souboru.

        Returns:
            bool: True, pokud byl povel úspěšně přidán. False, pokud povel s daným názvem již existuje.
        """
        # Zkontrolujeme, zda povel se stejným jménem již neexistuje
        if any(cmd['name'] == name for cmd in self.commands):
            print(f"Chyba: Povel s názvem '{name}' již existuje.")
            return False

        new_command = {
            "name": name,
            "shortcut": shortcut,
            "recording": recording_path
        }
        self.commands.append(new_command)
        self.save_commands()
        print(f"Povel '{name}' byl úspěšně přidán.")
        return True

    def delete_command(self, name: str) -> bool:
        """
        Smaže povel podle jeho názvu a také příslušný soubor s nahrávkou.

        Args:
            name (str): Název povelu k smazání.

        Returns:
            bool: True, pokud byl povel úspěšně smazán. False, pokud nebyl nalezen.
        """
        command_to_delete = self.find_command(name)

        if not command_to_delete:
            print(f"Chyba: Povel s názvem '{name}' nebyl nalezen.")
            return False

        # Smazání audio souboru, pokud existuje
        recording_path = command_to_delete.get('recording')
        if recording_path and os.path.exists(recording_path):
            try:
                os.remove(recording_path)
                print(f"Nahrávka '{recording_path}' byla smazána.")
            except OSError as e:
                print(f"Chyba při mazání souboru '{recording_path}': {e}")

        # Odstranění povelu ze seznamu
        self.commands = [cmd for cmd in self.commands if cmd['name'] != name]
        self.save_commands()
        print(f"Povel '{name}' byl úspěšně smazán.")
        return True

    def find_command(self, name: str) -> Optional[Dict[str, str]]:
        """
        Najde povel podle názvu.

        Args:
            name (str): Hledaný název povelu.

        Returns:
            Optional[Dict[str, str]]: Slovník s daty povelu, nebo None, pokud nebyl nalezen.
        """
        for command in self.commands:
            if command['name'] == name:
                return command
        return None

    def get_all_commands(self) -> List[Dict[str, str]]:
        """
        Vrátí celý seznam povelů.
        """
        return self.commands