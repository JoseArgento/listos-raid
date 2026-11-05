"""Listos para la raid in Lua 5.1 on a small stand-in for the client, with several guildmates side by side."""

from __future__ import annotations

from pathlib import Path

import pytest

lupa = pytest.importorskip("lupa.lua51")

ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "ListosParaLaRaid"
TESTS = Path(__file__).resolve().parent
ALLIANCE = [4182, 4183, 4184, 4185, 4186, 4223, 4224, 4241, 4242, 4264, 4282, 4322, 6402, 6403, 6501, 6502]


def toc_files():
    lines = (ADDON / "ListosParaLaRaid.toc").read_text(encoding="utf-8").splitlines()
    return [ln.strip().replace("\\", "/") for ln in lines if ln.strip() and not ln.startswith("#") and ln.strip().endswith(".lua")]


class Client:
    def __init__(self, name="Josecito", locale="enUS", saved=None, trial=False, guild="Los Del Fondo"):
        self.name = name
        self.lua = lupa.LuaRuntime(unpack_returned_tuples=True)
        for f in ("wow_mock.lua", "guild_mock.lua", "raid_mock.lua"):
            self.lua.execute((TESTS / f).read_text(encoding="utf-8"))
        self.m = self.lua.globals().MOCK
        self.m.player.name = name
        self.m.locale = locale
        self.m.trial = trial
        if guild is None:
            self.m.guild = None
        if saved is not None:
            self.lua.execute(saved)
        self.ns = self.lua.table()
        loader = self.lua.eval("function(src, name) return assert(loadstring(src, '@' .. name)) end")
        for rel in toc_files():
            loader((ADDON / rel).read_text(encoding="utf-8"), f"ListosParaLaRaid/{rel}")("ListosParaLaRaid", self.ns)

    def login(self):
        self.fire("ADDON_LOADED", "ListosParaLaRaid")
        self.fire("PLAYER_LOGIN")
        return self

    def run(self, code):
        return self.lua.eval("function(ns, MOCK) " + code + " end")(self.ns, self.m)

    def fire(self, event, *args):
        self.m.fire(event, *args)

    def timers(self):
        for _ in range(3):
            self.m.runTimers()

    def take_sent(self):
        s = self.m.sent
        out = [(s[i].prefix, s[i].text, s[i].chatType) for i in range(1, len(s) + 1)]
        self.run("MOCK.sent = {}")
        return out

    def receive(self, text, sender="Ana-Forever", channel="GUILD", prefix="ListosRaid1"):
        self.fire("CHAT_MSG_ADDON", prefix, text, channel, sender, "", 0, 0, "", 0)

    def status(self):
        s = self.ns.MyStatus()
        return (s.lv, s.am, s.st, s.of, s.fr)

    def lines(self):
        x = self.ns.UI.Lines()
        return x

    def guild(self):
        return {k: (v.lv, v.am, v.st, v.of, v.fr) for k, v in self.ns.Guild().items()}


def deliver(src: Client, *dests: Client):
    src.timers()
    for _p, text, chat in src.take_sent():
        assert chat == "GUILD"
        for d in dests:
            d.receive(text, sender=f"{src.name}-Forever")


@pytest.fixture
def me():
    return Client().login()


def test_status_from_level_quests_amulet_and_fire(me):
    me.m.player.level = 58
    for q in ALLIANCE[:5]:
        me.m.doneQuests[q] = True
    me.m.fireRes = 45
    assert me.status() == (58, False, 5, 16, 45)
    me.m.counts[16309] = 1
    assert me.status() == (58, True, 16, 16, 45)


def test_horde_has_its_own_chain():
    c = Client().login()
    c.m.faction = "Horde"
    assert c.status()[3] == 14


def test_ready_for_which_raids(me):
    me.m.player.level = 59
    assert list(me.ns.ReadyFor(me.ns.MyStatus()).values()) == []
    me.m.player.level = 60
    assert list(me.ns.ReadyFor(me.ns.MyStatus()).values()) == ["barrow", "hyjal"]
    me.m.counts[16309] = 1
    assert list(me.ns.ReadyFor(me.ns.MyStatus()).values()) == ["barrow", "hyjal", "onyxia"]


def test_countdown(me):
    me.m.now = me.run("return time({ year = 2026, month = 11, day = 4, hour = 9 })")
    assert me.ns.DaysLeft() == 35
    assert "35 days" in me.lines().countdown
    me.m.now = me.run("return time({ year = 2026, month = 12, day = 9, hour = 20 })")
    assert me.lines().countdown == "Raids open today!"
    me.m.now = me.m.now + 86400 * 3
    assert me.lines().countdown == "Raids are open."


def test_two_guildmates_see_each_other():
    a, b = Client("Josecito").login(), Client("Ana").login()
    a.m.player.level = 60
    a.m.counts[16309] = 1
    a.m.fireRes = 120
    deliver(a, b)
    assert b.guild()["Josecito"] == (60, True, 16, 16, 120)
    rows = list(b.lines().guild.values())
    assert rows[0].startswith("Josecito  ·  60  ·  ")
    assert b.lines().count == "Ready: 1 for Onyxia, 1 at level 60"


def test_changes_are_shared_once(me):
    me.timers()
    me.take_sent()
    me.m.player.level = 11
    me.fire("PLAYER_LEVEL_UP", 11)
    me.fire("QUEST_TURNED_IN", 1, 0, 0)  # nothing new about readiness: same message
    me.timers()
    sent = [t for _, t, _ in me.take_sent()]
    assert sent == ["S|1|11|0|0|16|0"]


def test_a_question_gets_an_answer_even_without_changes(me):
    me.timers()
    me.take_sent()
    me.receive("Q|1")
    me.timers()
    assert [t for _, t, _ in me.take_sent()] == ["S|1|10|0|0|16|0"]


@pytest.mark.parametrize(
    "kwargs",
    [
        {"channel": "PARTY"},
        {"prefix": "Otro"},
        {"text": "S|1|0|1|16|16|0"},  # level 0
        {"text": "S|1|61|2|16|16|0"},  # amulet must be 0 or 1
        {"text": "S|1|60|1|17|16|0"},  # more steps done than exist
        {"text": "S|1|60|1|16|16|5000"},  # absurd resistance
        {"text": "S|1|60|1|16|16|0|extra"},
        {"text": "loadstring('x')()"},
        {"sender": "Josecito-Forever"},
    ],
)
def test_bad_messages_are_ignored(me, kwargs):
    text = kwargs.pop("text", "S|1|60|1|16|16|50")
    me.receive(text, **kwargs)
    assert me.guild() == {}


def test_one_sender_cannot_flood(me):
    for lv in range(1, 10):
        me.receive(f"S|1|{lv}|0|0|16|0")
    assert me.guild()["Ana"][0] == 5


def test_trial_accounts_listen_only():
    t = Client("Prueba", trial=True).login()
    t.timers()
    assert t.take_sent() == []
    t.receive("S|1|60|1|16|16|50")
    assert "Ana" in t.guild()
    assert "Trial" in t.lines().note


def test_no_guild_shows_only_you():
    c = Client("Solo", guild=None).login()
    c.timers()
    assert c.take_sent() == []
    assert "not in a guild" in c.lines().note


def test_secret_values_count_as_nothing(me):
    me.m.counts[16309] = 1
    me.m.secret[1] = True  # the count came back secret
    assert me.status()[1] is False


def test_copy_list(me):
    me.receive("S|1|60|1|16|16|130", sender="Ana-Forever")
    text = me.ns.UI.ListText()
    assert text.splitlines() == ["name,level,amulet,step,steps,fire", "Josecito,10,0,0,16,0", "Ana,60,1,16,16,130"]
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("copiar")


def test_the_page_is_a_single_parchment_book(me):
    me.receive("S|1|60|1|16|16|130")
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("")
    f = me.ns.UI.frame
    assert f.IsShown(f) and f.single is True and f.right is None
    assert "leather" in str(f.leather.texture) and "page" in str(f.pageL.texture) and f.spine is None
    assert f.title.GetText(f.title) == "Ready for the raid"
    assert "Drakefire Amulet" in f.mine[2].GetText(f.mine[2])
    assert "34 days" in f.countdown.GetText(f.countdown) or "days to go" in f.countdown.GetText(f.countdown)
    # the guild lives in a list whose rows carry name, level, step/amulet and fire; Ana is ready for Onyxia
    rows = f.list.box.rows
    assert len(rows) == 1
    assert rows[1].name.GetText(rows[1].name) == "Ana" and rows[1].level.GetText(rows[1].level) == "60"
    assert "amulet" in rows[1].attune.GetText(rows[1].attune) and "fire 130" in rows[1].fire.GetText(rows[1].fire)
    assert rows[1].tag._shown is True
    # a guildmate who is not ready gets no tag and sorts after Ana
    me.receive("S|1|58|0|5|16|20", sender="Beto-Forever")
    rows = f.list.box.rows
    assert [rows[i].name.GetText(rows[i].name) for i in (1, 2)] == ["Ana", "Beto"]
    assert rows[2].tag._shown is False and "step 5/16" in rows[2].attune.GetText(rows[2].attune)
    # below level 50 the status block has three lines and the guild heading hangs from the last one
    me.m.player.level = 12
    me.ns.UI.Refresh()
    shown = [f.mine[i]._shown for i in range(1, 6)]
    assert shown == [True, True, True, False, False]
    # the wax seal closes the book
    f.close._scripts["OnClick"](f.close)
    assert f.IsShown(f) is False


def test_copy_opens_a_parchment_card_with_the_list_selected(me):
    me.receive("S|1|60|1|16|16|130")
    me.ns.UI.Copy()
    card = me.ns.UI.card
    assert card.IsShown(card) and card.title.GetText(card.title) == "Copy list"
    box = card.area.box
    assert box.GetText(box).splitlines()[0] == "name,level,amulet,step,steps,fire"
    assert "Ana,60,1,16,16,130" in box.GetText(box)


def test_language_can_be_chosen_regardless_of_the_client(me):
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("")
    f = me.ns.UI.frame
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("idioma es")
    assert me.m.savedVariables("ListosParaLaRaidDB").find('["lang"] = "es"') != -1
    assert "Amuleto de Fuego Dracónico" in me.lines().mine[2]
    assert f.title.GetText(f.title) == "Listos para la raid" and f.copy.GetText(f.copy) == "Copiar lista"
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("lang en")
    assert "Drakefire Amulet" in me.lines().mine[2] and f.title.GetText(f.title) == "Ready for the raid"
    me.lua.globals().SlashCmdList.LISTOSPARALARAID("idioma auto")
    assert "Drakefire Amulet" in me.lines().mine[2]
    # the choice survives a relog, and nonsense falls back to auto
    b = Client(saved=me.m.savedVariables("ListosParaLaRaidDB")).login()
    assert b.ns.lang == "auto"
    b.lua.globals().SlashCmdList.LISTOSPARALARAID("idioma es")
    c = Client(saved=b.m.savedVariables("ListosParaLaRaidDB")).login()
    assert c.ns.lang == "es" and "Amuleto" in c.lines().mine[2]
    c.lua.globals().SlashCmdList.LISTOSPARALARAID("idioma klingon")
    assert c.ns.lang == "auto"


def test_saved_and_loaded():
    a = Client().login()
    a.receive("S|1|60|1|16|16|130")
    b = Client(saved=a.m.savedVariables("ListosParaLaRaidDB")).login()
    assert b.guild()["Ana"] == (60, True, 16, 16, 130)


def test_spanish():
    c = Client(locale="esES").login()
    assert "Amuleto de Fuego Dracónico" in c.lines().mine[2]


def test_compartment(me):
    g = me.lua.globals()
    g.ListosParaLaRaid_OnAddonCompartmentClick()
    g.ListosParaLaRaid_OnAddonCompartmentEnter(None, me.ns.UI.frame)
    g.ListosParaLaRaid_OnAddonCompartmentLeave()


def test_below_the_chain_level_the_window_says_what_comes_first(me):
    me.m.player.level = 12
    mine = list(me.lines().mine.values())
    assert any("48 levels to go" in ln and "level 50" in ln for ln in mine)
    assert not any("step" in ln or "Fire resistance" in ln or "Not ready" in ln for ln in mine)
    me.m.player.level = 50
    mine = list(me.lines().mine.values())
    assert any("Attunement: step" in ln for ln in mine) and any("Fire resistance" in ln for ln in mine)
