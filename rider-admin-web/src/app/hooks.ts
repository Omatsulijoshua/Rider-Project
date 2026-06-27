import { store, type AppDispatch, type RootState } from "./store";

export const useAppDispatch = (): AppDispatch => store.dispatch;

export const useAppSelector = <T,>(selector: (state: RootState) => T): T =>
  selector(store.getState());
