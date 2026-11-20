import { jsonHeaders, limited } from '../../../lib/api';
export function GET(request:Request){if(limited(request))return Response.json({error:'Too many requests'},{status:429});return Response.json({assets:['BTC','ETH','BNB']},{headers:jsonHeaders(60)});}
