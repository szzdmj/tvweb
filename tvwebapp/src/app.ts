import express from 'express';
import { json } from 'body-parser';
import { router } from './routes'; // 假設有一個路由模組

const app = express();
const PORT = process.env.PORT || 3000;

app.use(json());
app.use('/api', router); // 設置路由

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});