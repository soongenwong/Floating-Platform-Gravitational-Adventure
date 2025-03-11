import boto3
import time

def create_platforms_table(tableName, dynamodb=None):
    if not dynamodb:
        dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
    
    # Use the tableName parameter here instead of hardcoded 'Platforms'
    table = dynamodb.create_table(
        TableName=tableName,
        KeySchema=[
            {
                'AttributeName': 'platform_id',
                'KeyType': 'HASH'  # Partition key
            }
        ],
        AttributeDefinitions=[
            {
                'AttributeName': 'platform_id',
                'AttributeType': 'S'
            }
        ],
        ProvisionedThroughput={
            'ReadCapacityUnits': 10,
            'WriteCapacityUnits': 10
        }
    )
    # Wait for table creation to complete
    table.meta.client.get_waiter('table_exists').wait(TableName=tableName)
    return table

if __name__ == '__main__':
    arr = ["Platforms", "MovingPlatforms", "BreakingPlatforms"]
    last_table = None
    
    for title in arr:
        try:
            print(f"Creating table: {title}")
            last_table = create_platforms_table(title)
            print(f"Table {title} created successfully. Status: {last_table.table_status}")
        except Exception as e:
            print(f"Error creating table {title}: {str(e)}")

    try:
        print("Creating table: FastestWins")
        fastest_wins_key_schema = [
            {
                'AttributeName': 'player_name',
                'KeyType': 'HASH'  # Partition key
            },
            {
                'AttributeName': 'timestamp',
                'KeyType': 'RANGE'  # Sort key
            }
        ]
        fastest_wins_attr_definitions = [
            {
                'AttributeName': 'player_name',
                'AttributeType': 'S'
            },
            {
                'AttributeName': 'timestamp',
                'AttributeType': 'S'
            }
        ]
        
        dynamodb = boto3.resource('dynamodb', region_name='eu-west-2')
        fastest_wins_table = dynamodb.create_table(
            TableName='FastestWins',
            KeySchema=fastest_wins_key_schema,
            AttributeDefinitions=fastest_wins_attr_definitions,
            ProvisionedThroughput={
                'ReadCapacityUnits': 10,
                'WriteCapacityUnits': 10
            }
        )
        
        # Wait for table creation to complete
        fastest_wins_table.meta.client.get_waiter('table_exists').wait(TableName='FastestWins')
        print(f"Table FastestWins created successfully. Status: {fastest_wins_table.table_status}")
        last_table = fastest_wins_table
    except Exception as e:
        print(f"Error creating table FastestWins: {str(e)}")
            
    if last_table:
        print("Final table status:", last_table.table_status)