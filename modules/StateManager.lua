StateManager.onEnter["FARMING"] = function()
    task.spawn(function()
        while StateManager.currentState == "FARMING" do
            if not NS.Config.autoFarmLevel then
                StateManager.setState("STOPPED")
                return
            end

            local quest = NS.LevelManager.getQuestRange()
            local enemy, dist

            if NS.Config.autoQuest and quest and quest.enemy then
                enemy, dist = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
            end
            if not enemy and NS.Config.farmNearest then
                enemy, dist = NS.TargetManager.findNearest()
            end
            if not enemy then
                enemy, dist = NS.TargetManager.findNearest()
            end

            if not enemy then
                NS.Logger.log("Sem inimigos disponíveis...")
                task.wait(0.5)
                continue
            end

            NS.Logger.log("Atacando:", enemy.Name, "dist:", math.floor(dist))

            if NS.Config.autoEquip then
                NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
            end

            if NS.Config.bringMob then
                NS.MovementManager.bringMob(enemy)
            end

            if NS.Config.bringMob then
                NS.MovementManager.hoverAbove(
                    enemy.HumanoidRootPart,
                    NS.Config.farmHeight
                )
            else
                NS.MovementManager.standNear(
                    enemy.HumanoidRootPart,
                    NS.Config.farmDistance,
                    NS.Config.farmHeight
                )
            end

            NS.CombatManager.attack()
            task.wait(NS.Config.attackDelay)
        end
    end)
end
