local self = {}

self.Currency = "USD"

self.StartingMoney = {1500, 0} -- Wallet, Bank
self.TransactionWait = 1

self.TaskPay = true
self.Salaries = {
	["Garbage"] = {200, true}, -- Cash / To wallet
	["Mail"] = {250, true}, 
	["FoodDelivery"] = {300, false},
	["Taxi"] = {500, true},
}

self.EnablePaycheks = false
self.PaycheckList = {
	["Police Department"] = {200, 5, true} -- Cash / Minutes / To wallet
}

self.EnableRob = true
self.RobAmount = {20, 0.5, 100, 1000, 120} -- Times / Rate / Min / Max / Cooldown

self.Jobs = {
	
	["DeliverFood"] = {
		
		Icon = "rbxassetid://12528175021",
		Organization = "Food Inc.",
		Proffesion = "Food Delivery",
		
		Salary = {
			Min = 50,
			Max = 100
		},
		
		About = "Your job is to deliver food to different parts of the city as quickly as possible.",
		Place = "Your city"
		
	},
	
	["Mail"] = {
		
		Icon = "rbxassetid://6035056477",
		Organization = "City mail",
		Proffesion = "Mailman",
		
		Salary = {
			Min = 50,
			Max = 100
		},
		
		About = "Receive and deliver parcels from the mail office to people.",
		Place = "Your city"
		
	},
	
	["Garbage"] = {
		
		Icon = "rbxassetid://6035056477",
		Organization = "Government",
		Proffesion = "Garbageman",
		
		Salary = {
			Min = 50,
			Max = 100
		},
		
		About = "Pick up trash and put it in a trash bin",
		Place = "Your city"
		
	}
	
}

return self