local Quests = {}

Quests[1] = {
    {minLevel = 1,   maxLevel = 9,   mob = "Bandit",              questName = "BanditQuest1",  questId = 1, npcPos = CFrame.new(1045.962646, 27.002508, 1560.820312),  mobPos = CFrame.new(1100, 30, 1600)},
    {minLevel = 10,  maxLevel = 14,  mob = "Monkey",              questName = "JungleQuest",   questId = 1, npcPos = CFrame.new(-1598.08911, 35.550117, 153.377838),  mobPos = CFrame.new(-1448.51807, 67.853012, 11.465796)},
    {minLevel = 15,  maxLevel = 29,  mob = "Gorilla",             questName = "JungleQuest",   questId = 2, npcPos = CFrame.new(-1598.08911, 35.550117, 153.377838),  mobPos = CFrame.new(-1129.88367, 40.463547, -525.423706)},
    {minLevel = 30,  maxLevel = 39,  mob = "Pirate",              questName = "BuggyQuest1",   questId = 1, npcPos = CFrame.new(-1141.07483, 4.100018, 3831.5498),    mobPos = CFrame.new(-1103.51343, 13.752052, 3896.09106)},
    {minLevel = 40,  maxLevel = 59,  mob = "Brute",               questName = "BuggyQuest1",   questId = 2, npcPos = CFrame.new(-1141.07483, 4.100018, 3831.5498),    mobPos = CFrame.new(-1140.08374, 14.809885, 4322.92139)},
    {minLevel = 60,  maxLevel = 74,  mob = "Desert Bandit",       questName = "DesertQuest",   questId = 1, npcPos = CFrame.new(894.488647, 5.140007, 4392.43359),     mobPos = CFrame.new(924.799805, 6.448675, 4481.58594)},
    {minLevel = 75,  maxLevel = 89,  mob = "Desert Officer",      questName = "DesertQuest",   questId = 2, npcPos = CFrame.new(894.488647, 5.140007, 4392.43359),     mobPos = CFrame.new(1608.28223, 8.614224, 4371.00732)},
    {minLevel = 90,  maxLevel = 99,  mob = "Snow Bandit",         questName = "SnowQuest",     questId = 1, npcPos = CFrame.new(1389.74451, 88.151932, -1298.90796),   mobPos = CFrame.new(1354.3479, 87.272774, -1393.94653)},
    {minLevel = 100, maxLevel = 119, mob = "Snowman",             questName = "SnowQuest",     questId = 2, npcPos = CFrame.new(1389.74451, 88.151932, -1298.90796),   mobPos = CFrame.new(1201.64124, 144.57959, -1550.06702)},
    {minLevel = 120, maxLevel = 149, mob = "Chief Petty Officer", questName = "MarineQuest2",  questId = 1, npcPos = CFrame.new(-5039.58643, 27.350038, 4324.68018),   mobPos = CFrame.new(-4881.23096, 22.652044, 4273.75244)},
    {minLevel = 150, maxLevel = 174, mob = "Sky Bandit",          questName = "SkyQuest",      questId = 1, npcPos = CFrame.new(-4839.53027, 716.368591, -2619.44165),  mobPos = CFrame.new(-4953.20703, 295.744202, -2899.229)},
    {minLevel = 175, maxLevel = 189, mob = "Dark Master",         questName = "SkyQuest",      questId = 2, npcPos = CFrame.new(-4839.53027, 716.368591, -2619.44165),  mobPos = CFrame.new(-5259.84473, 391.397675, -2229.0354)},
    {minLevel = 190, maxLevel = 209, mob = "Prisoner",            questName = "PrisonerQuest", questId = 1, npcPos = CFrame.new(5308.93115, 1.655175, 475.120514),     mobPos = CFrame.new(5098.97363, -0.320406, 474.237335)},
    {minLevel = 210, maxLevel = 249, mob = "Dangerous Prisoner",  questName = "PrisonerQuest", questId = 2, npcPos = CFrame.new(5308.93115, 1.655175, 475.120514),     mobPos = CFrame.new(5654.56348, 15.633402, 866.299194)},
    {minLevel = 250, maxLevel = 274, mob = "Toga Warrior",        questName = "ColosseumQuest",questId = 1, npcPos = CFrame.new(-1580.04663, 6.350003, -2986.47534),  mobPos = CFrame.new(-1820.21484, 51.683857, -2740.66504)},
    {minLevel = 275, maxLevel = 299, mob = "Gladiator",           questName = "ColosseumQuest",questId = 2, npcPos = CFrame.new(-1580.04663, 6.350003, -2986.47534),  mobPos = CFrame.new(-1292.83813, 56.380882, -3339.03149)},
    {minLevel = 300, maxLevel = 324, mob = "Military Soldier",    questName = "MagmaQuest",    questId = 1, npcPos = CFrame.new(-5313.37012, 10.950008, 8515.29395),   mobPos = CFrame.new(-5411.16455, 11.081554, 8454.29297)},
    {minLevel = 325, maxLevel = 374, mob = "Military Spy",        questName = "MagmaQuest",    questId = 2, npcPos = CFrame.new(-5313.37012, 10.950008, 8515.29395),   mobPos = CFrame.new(-5802.86816, 86.262413, 8828.85938)},
    {minLevel = 375, maxLevel = 399, mob = "Fishman Warrior",     questName = "FishmanQuest",  questId = 1, npcPos = CFrame.new(61122.6523, 18.497442, 1569.39978),    mobPos = CFrame.new(60878.3008, 18.48283, 1543.75745)},
    {minLevel = 400, maxLevel = 449, mob = "Fishman Commando",    questName = "FishmanQuest",  questId = 2, npcPos = CFrame.new(61122.6523, 18.497442, 1569.39978),    mobPos = CFrame.new(61922.6328, 18.48283, 1493.93433)},
    {minLevel = 450, maxLevel = 474, mob = "God's Guard",         questName = "SkyExp1Quest",  questId = 1, npcPos = CFrame.new(-4721.88867, 843.874695, -1949.96643),mobPos = CFrame.new(-4710.04297, 845.276978, -1927.30798)},
    {minLevel = 475, maxLevel = 524, mob = "Shanda",              questName = "SkyExp1Quest",  questId = 2, npcPos = CFrame.new(-7859.09814, 5544.19043, -381.476196), mobPos = CFrame.new(-7678.48975, 5566.40381, -497.215607)},
    {minLevel = 525, maxLevel = 549, mob = "Royal Squad",         questName = "SkyExp2Quest",  questId = 1, npcPos = CFrame.new(-7906.81592, 5634.6626, -1411.99194), mobPos = CFrame.new(-7624.25244, 5658.1333, -1467.35425)},
    {minLevel = 550, maxLevel = 624, mob = "Royal Soldier",       questName = "SkyExp2Quest",  questId = 2, npcPos = CFrame.new(-7906.81592, 5634.6626, -1411.99194), mobPos = CFrame.new(-7836.75342, 5645.66406, -1790.62366)},
    {minLevel = 625, maxLevel = 649, mob = "Galley Pirate",       questName = "FountainQuest", questId = 1, npcPos = CFrame.new(5259.81982, 37.350017, 4050.0293),    mobPos = CFrame.new(5551.02197, 78.901352, 3930.41284)},
    {minLevel = 650, maxLevel = 999, mob = "Galley Captain",      questName = "FountainQuest", questId = 2, npcPos = CFrame.new(5259.81982, 37.350017, 4050.0293),    mobPos = CFrame.new(5441.95166, 42.50206, 4950.09375)},
}

function Quests.getByLevel(level)
    for _, quest in ipairs(Quests[1]) do
        if level >= quest.minLevel and level <= quest.maxLevel then
            return quest
        end
    end
    return Quests[1][#Quests[1]]
end

return Quests