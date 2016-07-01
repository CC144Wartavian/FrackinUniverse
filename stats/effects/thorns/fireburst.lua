function init()
  self.minRange = effect.configParameter("minRange") or 0.5

  self.visualProjectileType = effect.configParameter("visualProjectileType")
  self.visualProjectileCount = effect.configParameter("visualProjectileCount") or 20
  self.visualProjectileSpeed = effect.configParameter("visualProjectileSpeed") or 20
  self.visualProjectileTime = effect.configParameter("visualProjectileTime")
  self.visualDuration = effect.configParameter("visualDuration") or 0.2

  self.damageProjectileType = effect.configParameter("damageProjectileType") or "armorthornburst"
  self.damageMultiplier = effect.configParameter("damageMultiplier") or 0.06
  self.fadeColor = effect.configParameter("fadeColor")
  self.border = effect.configParameter("border")

  self.cooldown = effect.configParameter("cooldown") or 5

  self.removeInWater = effect.configParameter("removeInWater")

  self.minTriggerDamage = effect.configParameter("minTriggerDamage") or 0

  resetThorns()
  self.cooldownTimer = 0

  if self.border then
    effect.setParentDirectives("border="..self.border)
  end
end

function resetThorns()
  self.cooldownTimer = self.cooldown
  self.triggerThorns = false
  self.thornsTimer = 0
  self.spawnedThorns = 0
  self.thornDamage = 0

  effect.setParentDirectives("")
end

function update(dt)
  if self.removeInWater then
    if effect.duration() and world.liquidAt({mcontroller.xPosition(), mcontroller.yPosition() - 1}) then
      effect.expire()
    end
  end

  if self.cooldownTimer > 0 then
    self.cooldownTimer = self.cooldownTimer - dt
  end

  if self.triggerThorns then
    self.thornsTimer = self.thornsTimer - dt

    local fadeOpacity = ((self.visualProjectileCount - self.spawnedThorns) / self.visualProjectileCount) * 0.8

    if self.fadeColor then
      effect.setParentDirectives("fade="..self.fadeColor.."="..fadeOpacity)
    end

    if self.thornsTimer <= 0 then
      local thornCount
      local visualInterval = self.visualDuration / self.visualProjectileCount
      
      if not self.visualDuration or self.visualDuration <= 0 then
        thornCount = self.visualProjectileCount
      else
        --It's possible we need to spawn several thorns because they need to spawn very fast
        thornCount = math.floor((visualInterval - self.thornsTimer) / visualInterval)
        thornCount = math.min(thornCount, self.visualProjectileCount - self.spawnedThorns)
      end

      spawnVisualThorns(thornCount)

      self.thornsTimer = self.thornsTimer + thornCount * visualInterval

      if self.spawnedThorns >= self.visualProjectileCount then resetThorns() end
    end
  end
end

function spawnVisualThorns(count)
  if count == nil then count = 1 end
  local pi = 3.14

  local randAngle = math.random() * 2 * pi --Random radian
  local angleInterval = math.pi * 2 / count
  for x = 0, count - 1 do
    local angle = randAngle + angleInterval * x
    local needleVector = {math.cos(angle), math.sin(angle)}

    local position = mcontroller.position()
    local visualConfig = {
      power = 0, 
      timeToLive = self.visualProjectileTime,
      speed = self.visualProjectileSpeed,
      physics = "default"
    }
    world.spawnProjectile(self.visualProjectileType, position, entity.id(), needleVector, true, visualConfig)

    self.spawnedThorns = self.spawnedThorns + 1
  end
end

function triggerThorns(damage)
  if self.visualProjectileType then
    self.triggerThorns = true
    self.thornDamage = damage
    self.thornsTimer = self.visualDuration
  end

  local damageConfig = {
    power = damage,
    speed = 0,
    physics = "default"
  }
  world.spawnProjectile(self.damageProjectileType, mcontroller.position(), entity.id(), {0, 0}, true, damageConfig)
end

function selfDamage(notification)
  if self.cooldownTimer <= 0 and notification.damage > self.minTriggerDamage and notification.sourceEntityId ~= notification.targetEntityId then
    triggerThorns(notification.damage * self.damageMultiplier)
    self.cooldownTimer = self.cooldown
  end
end
