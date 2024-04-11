import type { APIGatewayProxyEvent, APIGatewayProxyResult } from "aws-lambda";

export const run = async (
	_: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
	return {
		statusCode: 200,
		body: JSON.stringify({
			message: "Hello World!",
		}),
	};
};
