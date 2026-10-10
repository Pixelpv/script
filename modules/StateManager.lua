StateManager.onEnter["FARMING"] = function()
    task.spawn(function()
        while StateManager.currentState == "FARMING" do
            if not NS.Config.autoFarmLevel then
                StateManager.setState("STOPPED")
                return
            end

            local quest = NS.LevelManager.getQuestRange()
            local enemy, dist
            local modo

            -- Auto Quest: prioridade no mob da quest
            if NS.Config.autoQuest and quest and quest.enemy then
                enemy, dist = NS.TargetManager.findNearestQuestEnemy(quest.enemy)
                modo = "quest"
            end

            -- Farm Nearest: fallback ou modo principal
            if not enemy and NS.Config.farmNearest then
                enemy, dist = NS.TargetManager.findNearest()
                modo = "nearest"
            end

            -- Último fallback: pega qualquer um pra não travar
            if not enemy then
                enemy, dist = NS.TargetManager.findNearest()
                modo = "fallback"
            end

            if not enemy then
                NS.Logger.log("Nenhum mob disponível na região...")
                task.wait(0.5)
                continue
            end

            NS.Logger.log("Atacando:", enemy.Name, "| modo:", modo, "| dist:", math.floor(dist))

            -- Auto Equip
            if NS.Config.autoEquip then
                NS.CombatManager.equipWeaponType(NS.Config.selectWeapon)
            end

            -- Bring Mob
            if NS.Config.bringMob then
                NS.MovementManager.bringMob(enemy)
            end

            -- Movimento
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

            -- Ataque
            NS.CombatManager.attack()
            task.wait(NS.Config.attackDelay)
        end
    end)
end
