FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY ["src/Workers/Inventory.Worker/Inventory.Worker.csproj", "src/Workers/Inventory.Worker/"]
COPY ["src/Shared/Shared.Contracts/Shared.Contracts.csproj", "src/Shared/Shared.Contracts/"]
COPY ["src/Shared/Shared.Observability/Shared.Observability.csproj", "src/Shared/Shared.Observability/"]
RUN dotnet restore "src/Workers/Inventory.Worker/Inventory.Worker.csproj"
COPY . .
WORKDIR "/src/src/Workers/Inventory.Worker"
RUN dotnet build "Inventory.Worker.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "Inventory.Worker.csproj" -c Release -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "Inventory.Worker.dll"]

