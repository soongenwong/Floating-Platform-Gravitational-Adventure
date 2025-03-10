extends Node

const AWS_REGION = "your-region" # e.g., "us-east-1"
const AWS_ACCESS_KEY = "your-access-key"
const AWS_SECRET_KEY = "your-secret-key"
const DYNAMODB_ENDPOINT = "https://dynamodb." + AWS_REGION + ".amazonaws.com"
const TABLE_NAME = "your-table-name"

var http_request = HTTPRequest.new()
@onready var text_edit = $TextEdit

var best_time = 0

func _ready():
    add_child(http_request)
    http_request.request_completed.connect(_on_request_completed)
    
    # Fetch the current best time when the game starts
    fetch_best_time()

func fetch_best_time():
    var current_time = Time.get_unix_time_from_system()
    var date = Time.get_datetime_string_from_unix_time(current_time, false)
    date = date.split("T")[0]
    
    var payload = JSON.stringify({
        "TableName": TABLE_NAME,
        "Key": {
            "game_id": {"S": "fastest_win"}
        }
    })
    
    var headers = _get_dynamodb_headers("GetItem", payload)
    
    http_request.request(DYNAMODB_ENDPOINT, headers, HTTPClient.METHOD_POST, payload)

func update_best_time(new_time):
    if new_time >= best_time:
        return
        
    best_time = new_time
    
    var payload = JSON.stringify({
        "TableName": TABLE_NAME,
        "Item": {
            "game_id": {"S": "fastest_win"},
            "time_seconds": {"N": str(new_time)}
        }
    })
    
    var headers = _get_dynamodb_headers("PutItem", payload)
    
    http_request.request(DYNAMODB_ENDPOINT, headers, HTTPClient.METHOD_POST, payload)
    
    # Update UI
    update_text_display()

func _on_request_completed(result, response_code, headers, body):
    if result != HTTPRequest.RESULT_SUCCESS:
        print("Error with the request: ", result)
        return
        
    if response_code != 200:
        print("DynamoDB response error: ", response_code)
        print("Response body: ", body.get_string_from_utf8())
        return
        
    var response = JSON.parse_string(body.get_string_from_utf8())
    
    if "Item" in response:
        if "time_seconds" in response["Item"]:
            best_time = float(response["Item"]["time_seconds"]["N"])
            update_text_display()
    
func update_text_display():
    text_edit.placeholder_text = "You Win!\nAll time fastest win: " + str(best_time) + " seconds"

func _get_dynamodb_headers(operation, payload):
    var date = Time.get_datetime_string_from_system()
    date = date.split("T")[0]
    
    var headers = [
        "Content-Type: application/x-amz-json-1.0",
        "X-Amz-Target: DynamoDB_20120810." + operation,
        "Host: dynamodb." + AWS_REGION + ".amazonaws.com",
        "X-Amz-Date: " + date + "T000000Z", # Simplified for example
    ]
    
    headers.append("Authorization: AWS4-HMAC-SHA256 Credential=" + AWS_ACCESS_KEY + "/" + 
                   date + "/" + AWS_REGION + "/dynamodb/aws4_request, " +
                   "SignedHeaders=content-type;host;x-amz-date;x-amz-target, Signature=dummy_signature")
    
    return headers

# Call this when the player wins the game
func on_player_win(time_seconds):
    update_best_time(time_seconds)