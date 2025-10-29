export interface ExampleType {
    id: number;
    name: string;
    isActive: boolean;
}

export type ExampleArray = ExampleType[];

export type Response<T> = {
    data: T;
    error?: string;
};