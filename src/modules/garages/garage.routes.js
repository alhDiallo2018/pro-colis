import { Router } from 'express';
import * as garageController from './garage.controller.js';

export const garageRouter = Router();

garageRouter.get('/', garageController.listPublicGarages);
