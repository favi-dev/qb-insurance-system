Config = {}

-- General Settings
Config.Debug = false
Config.UseTarget = true -- Use qb-target for interactions
Config.InsuranceOffice = vector3(-1082.1, -247.67, 37.76) -- الموقع
Config.InsuranceBlip = {
    sprite = 523,
    color = 2,
    scale = 0.7,
    label = "مكتب التأمين"
}

-- Insurance Types and Costs
Config.VehicleInsurance = {
    basic = {
        label = "التغطية الأساسية",
        price = 1500, -- One-time payment
        monthlyFee = 150,
        coverage = 0.6, -- Covers 60% of repair costs
        description = "التغطية الأساسية لأضرار المركبة"
    },
    standard = {
        label = "التغطية القياسية",
        price = 3000,
        monthlyFee = 300,
        coverage = 0.8, -- Covers 80% of repair costs
        description = "التغطية القياسية لأضرار المركبة"
    },
    premium = {
        label = "التغطية المميزة",
        price = 5000,
        monthlyFee = 500,
        coverage = 1.0, -- Covers 100% of repair costs or full replacement
        description = "التغطية الكاملة لأضرار المركبة"
    }
}

Config.PropertyInsurance = {
    basic = {
        label = "التغطية الأساسية للممتلكات",
        price = 2000,
        monthlyFee = 200,
        coverage = 0.5, -- Covers 50% of property damage
        description = "التغطية الأساسية للممتلكات"
    },
    premium = {
        label = "التغطية المميزة للممتلكات",
        price = 4000,
        monthlyFee = 400,
        coverage = 0.9, -- Covers 90% of property damage
        description = "التغطية الكاملة للممتلكات"
    }
}

Config.HealthInsurance = {
    basic = {
        label = "التغطية الصحية الأساسية",
        price = 1000,
        monthlyFee = 100,
        coverage = 0.4, -- Covers 40% of hospital bills
        description = "التغطية الصحية الأساسية"
    },
    premium = {
        label = "التغطية الصحية المميزة",
        price = 3000,
        monthlyFee = 300,
        coverage = 0.8, -- Covers 80% of hospital bills
        description = "التغطية الصحية الكاملة"
    }
}

-- Claim Processing
Config.ClaimProcessingTime = 5 * 60 * 1000 -- 5 minutes in milliseconds
Config.FraudChance = 0.1 -- 10% chance of triggering a fraud investigation for claims

-- Insurance Job
Config.InsuranceJob = "التأمين"
Config.JobGrades = {
    [0] = {
        name = "متدرب",
        label = "متدرب",
        payment = 50
    },
    [1] = {
        name = "وكيل",
        label = "وكيل التأمين",
        payment = 75
    },
    [2] = {
        name = "محقق",
        label = "محقق المطالبات",
        payment = 100
    },
    [3] = {
        name = "مدير",
        label = "مدير المكتب",
        payment = 125
    },
    [4] = {
        name = "مدير عام",
        label = "مدير التأمين",
        payment = 150,
        isboss = true
    }
}