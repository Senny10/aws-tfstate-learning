import { DynamoDB } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocument } from "@aws-sdk/lib-dynamodb";
import type { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

const db = DynamoDBDocument.from(new DynamoDB({}));

export const run = async (
	event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
	const body = JSON.parse(event.body);
	const catName = body.catName;
	const lastFed = body.lastFed;
	await db.put({
		TableName: process.env.TABLE_NAME,
		Item: { catname: catName, lastfed: lastFed },
	});

	return {
		statusCode: 201,
	};
};
