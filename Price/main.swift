import Foundation
import RainbowSwift

let sema = DispatchSemaphore( value: 0)
let dateFormatterGet = DateFormatter()
dateFormatterGet.dateFormat = "dd-MM-yy HH:mm"


extension Double {
	//rounds the double to decimal places value
	func roundTo(places:Int) -> Double {
		let divisor = pow(10.0, Double(places))
		return (self * divisor).rounded() / divisor
	}
}

extension Double {
	func string(fractionDigits:Int) -> String {
		let formatter = NumberFormatter()
		formatter.minimumFractionDigits = fractionDigits
		formatter.maximumFractionDigits = fractionDigits
		return formatter.string(from:NSNumber(value: self)) ?? "\(self)"
	}
}

func priceFetch() -> ()
{
	//set up the URL request
	let poloAPI: String = "https://poloniex.com/public?command=returnTicker"
	guard let url = URL(string: poloAPI) else {
		print("Price \(NSDate()): cannot create URL: \(poloAPI)")
		return
	}
	
	let urlRequest = URLRequest(url: url)
	
	//make the request
	let task = URLSession.shared.dataTask(with: urlRequest, completionHandler:
	{
		(data, response, error) in
		
		//make sure we got data
		guard let responseData = data else {
			print("Price \(NSDate()): did not receive data")
			sema.signal()
			return
		}
		//parse the result as json, since that's what the API provides
		do {
			guard let jsonResponse = try JSONSerialization.jsonObject(with: responseData, options: []) as? [String: AnyObject] else {
				print("Price \(NSDate()): error trying to convert data to JSON")
				sema.signal()
				return
			}
			
			var xmrParsedNotionalDictionary:[String:Double] = ["usd": 0.00, "btc": 0.00, "move": 0.00]
			
			//package up dictionary of associated notional values
			xmrParsedNotionalDictionary["usd"] = (Double)(jsonResponse["USDT_XMR"]!["last"]! as! String? ?? "0.00")?.roundTo(places: 2)
			xmrParsedNotionalDictionary["btc"] = (Double)(jsonResponse["BTC_XMR"]!["last"]! as! String? ?? "0.00")?.roundTo(places: 6)
			xmrParsedNotionalDictionary["move"] = (Double)(jsonResponse["USDT_XMR"]!["percentChange"]! as! String? ?? "0.00")?.roundTo(places: 3)
			xmrParsedNotionalDictionary["move"]=xmrParsedNotionalDictionary["move"]!*100

			print("Monero Market".bold.red, terminator:"")
			print("@".bold.blue, terminator:"")
			print("(\(dateFormatterGet.string(from: Date()).magenta)".bold.red, terminator:"")
			print(")".bold.red, terminator:"")
			print("/".bold, terminator:"")
			print("BTC: ".bold.yellow, terminator:"")
			print("\(xmrParsedNotionalDictionary["btc"] ?? 0)".bold.green, terminator:" - ")
			print("USD: ".bold.yellow, terminator:"")
			print("\(xmrParsedNotionalDictionary["usd"] ?? 0)".bold.green, terminator:" ")
			print("(\(xmrParsedNotionalDictionary["move"] ?? 0)%)".bold.cyan)

			sema.signal()
		}
		catch  {
			print("Price \(NSDate()): error trying to convert data to JSON")
			return
		}
	});
	task.resume()
	sema.wait()
}
priceFetch()
